const { ethers } = require('ethers');
const EventEmitter = require('events');
const fs = require('fs');
const path = require('path');

class StrategyBuilder extends EventEmitter {
    constructor(tradingEngine, sinclaveEngine, config) {
        super();
        this.tradingEngine = tradingEngine;
        this.sinclaveEngine = sinclaveEngine;
        this.config = config;
        
        // Strategy storage
        this.customStrategies = new Map(); // strategyId -> strategy config
        this.activeStrategies = new Map(); // strategyId -> execution state
        this.strategyPositions = new Map(); // strategyId -> positions array
        this.priceHistory = new Map(); // tokenAddress -> price history for DIP detection
        this.monitoringIntervals = new Map(); // strategyId -> interval ID
        
        // File paths
        this.strategiesPath = path.join(process.cwd(), 'custom-strategies.json');
        this.strategyPositionsPath = path.join(process.cwd(), 'strategy-positions.json');
        
        // WLD token address
        this.WLD_ADDRESS = '0x2cfc85d8e48f8eab294be644d9e25c3030863003';
        
        // Load existing strategies
        this.loadStrategies();
        
        console.log('🎯 Strategy Builder initialized');
    }
    
    // Create a new custom strategy
    createStrategy(config) {
        const strategyId = `strategy_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        const strategy = {
            id: strategyId,
            name: config.name || `Strategy for ${config.tokenSymbol}`,
            
            // Pair configuration
            baseToken: this.WLD_ADDRESS, // Always WLD
            targetToken: config.targetToken,
            tokenSymbol: config.tokenSymbol,
            
            // Trading parameters
            dipThreshold: config.dipThreshold || 15, // % drop to trigger buy
            profitTarget: config.profitTarget || 1, // % gain to trigger sell (legacy/simple mode)
            tradeAmount: config.tradeAmount || 0.1, // WLD amount per trade
            maxSlippage: config.maxSlippage || 1, // Max slippage %
            
            // Enhanced Profit Range Settings
            enableProfitRange: config.enableProfitRange || false,
            profitRangeMin: config.profitRangeMin || config.profitTarget || 1, // Min % to start selling
            profitRangeMax: config.profitRangeMax || (config.profitTarget || 1) * 2, // Max % to finish selling
            profitRangeSteps: config.profitRangeSteps || 3, // Number of partial sells in range
            profitRangeMode: config.profitRangeMode || 'linear', // 'linear', 'aggressive', 'conservative'
            
            // Enhanced DIP detection settings
            priceCheckInterval: config.priceCheckInterval || 30000, // 30 seconds for more frequent checks
            dipTimeframe: config.dipTimeframe || 300000, // Default: 5 minutes (300000ms)
            dipTimeframeLabel: this.getTimeframeLabel(config.dipTimeframe || 300000),
            
            // Historical price analysis settings
            enableHistoricalComparison: config.enableHistoricalComparison || false,
            historicalTimeframes: config.historicalTimeframes || {
                '5min': 300000,    // 5 minutes
                '1hour': 3600000,  // 1 hour  
                '6hour': 21600000, // 6 hours
                '24hour': 86400000, // 24 hours
                '7day': 604800000  // 7 days
            },
            
            // Strategy state
            isActive: false,
            createdAt: Date.now(),
            lastExecuted: null,
            
            // Performance tracking
            totalTrades: 0,
            successfulTrades: 0,
            totalProfit: 0,
            positions: []
        };
        
        this.customStrategies.set(strategyId, strategy);
        this.saveStrategies();
        
        console.log(`✅ Strategy created: ${strategy.name} (${strategyId})`);
        console.log(`   📊 Pair: WLD → ${config.tokenSymbol}`);
        console.log(`   📉 DIP Trigger: ${config.dipThreshold}% drop from highest in ${strategy.dipTimeframeLabel}`);
        
        if (strategy.enableProfitRange) {
            console.log(`   📈 Profit Range: ${strategy.profitRangeMin}% - ${strategy.profitRangeMax}% (${strategy.profitRangeSteps} steps, ${strategy.profitRangeMode} mode)`);
        } else {
            console.log(`   📈 Profit Target: ${config.profitTarget}% (simple mode)`);
        }
        
        console.log(`   💰 Trade Amount: ${config.tradeAmount} WLD`);
        console.log(`   ⏱️ Price Checks: Every ${strategy.priceCheckInterval / 1000}s`);
        
        return strategy;
    }
    
    // Helper method to convert timeframe to readable label
    getTimeframeLabel(timeframeMs) {
        const minutes = timeframeMs / 60000;
        const hours = minutes / 60;
        const days = hours / 24;
        
        if (days >= 1) {
            return `${days}d`;
        } else if (hours >= 1) {
            return `${hours}h`;
        } else {
            return `${minutes}min`;
        }
    }
    
    // Start monitoring a strategy
    startStrategy(strategyId, walletObject) {
        const strategy = this.customStrategies.get(strategyId);
        if (!strategy) {
            throw new Error(`Strategy ${strategyId} not found`);
        }
        
        if (strategy.isActive) {
            throw new Error(`Strategy ${strategy.name} is already active`);
        }
        
        strategy.isActive = true;
        strategy.walletObject = walletObject;
        
        // Initialize enhanced price history storage
        if (!this.priceHistory.has(strategy.targetToken)) {
            this.priceHistory.set(strategy.targetToken, {
                prices: [], // Array of {timestamp, price} objects
                maxHistoryAge: Math.max(604800000, strategy.dipTimeframe * 2) // Keep 7 days or 2x dipTimeframe, whichever is longer
            });
        }
        
        // Start monitoring interval
        const intervalId = setInterval(async () => {
            try {
                await this.monitorStrategy(strategyId);
            } catch (error) {
                console.error(`❌ Error monitoring strategy ${strategy.name}:`, error.message);
            }
        }, strategy.priceCheckInterval);
        
        this.monitoringIntervals.set(strategyId, intervalId);
        this.activeStrategies.set(strategyId, {
            startTime: Date.now(),
            lastCheck: null,
            checksPerformed: 0
        });
        
        console.log(`🚀 Started strategy: ${strategy.name}`);
        console.log(`   🔄 Monitoring every ${strategy.priceCheckInterval / 1000} seconds`);
        console.log(`   📊 Looking for ${strategy.dipThreshold}% DIP from highest price in ${strategy.dipTimeframeLabel}`);
        console.log(`   📈 Historical tracking: ${strategy.enableHistoricalComparison ? 'ENABLED' : 'DISABLED'}`);
        console.log(`   ⏳ WAITING for price drop - will NOT buy until DIP detected`);
        
        this.saveStrategies();
        return strategy;
    }
    
    // Stop monitoring a strategy
    stopStrategy(strategyId) {
        const strategy = this.customStrategies.get(strategyId);
        if (!strategy) {
            throw new Error(`Strategy ${strategyId} not found`);
        }
        
        strategy.isActive = false;
        
        // Clear monitoring interval
        const intervalId = this.monitoringIntervals.get(strategyId);
        if (intervalId) {
            clearInterval(intervalId);
            this.monitoringIntervals.delete(strategyId);
        }
        
        this.activeStrategies.delete(strategyId);
        
        console.log(`🛑 Stopped strategy: ${strategy.name}`);
        this.saveStrategies();
        return strategy;
    }
    
    // Monitor a strategy for DIP opportunities and profit targets
    async monitorStrategy(strategyId) {
        const strategy = this.customStrategies.get(strategyId);
        const activeState = this.activeStrategies.get(strategyId);
        
        if (!strategy || !activeState) return;
        
        activeState.lastCheck = Date.now();
        activeState.checksPerformed++;
        
        try {
            // Get current price using HoldStation SDK
            const currentPrice = await this.getCurrentPrice(strategy.targetToken);
            
            // Store price in enhanced history
            const priceHistoryData = this.priceHistory.get(strategy.targetToken);
            const priceHistory = priceHistoryData.prices;
            
            priceHistory.push({
                timestamp: Date.now(),
                price: currentPrice
            });
            
            // Clean old history (keep maxHistoryAge for historical analysis)
            const cutoffTime = Date.now() - priceHistoryData.maxHistoryAge;
            while (priceHistory.length > 0 && priceHistory[0].timestamp < cutoffTime) {
                priceHistory.shift();
            }
            
            // Check for open positions first
            const openPositions = strategy.positions.filter(p => p.status === 'open');
            
            if (openPositions.length > 0) {
                // Monitor existing positions for profit targets
                for (const position of openPositions) {
                    await this.checkPositionForProfit(strategy, position);
                }
            } else {
                // Look for DIP buying opportunities with enhanced analysis
                await this.checkForDipOpportunity(strategy, priceHistory, currentPrice);
            }
            
            // Brief status update every 2 checks (~10 seconds)
            if (activeState.checksPerformed % 2 === 0) {
                const timeRunning = Math.floor((Date.now() - activeState.startTime) / 1000);
                
                if (openPositions.length === 0) {
                    // Show enhanced DIP waiting status
                    if (priceHistory.length >= 2) {
                        // Get prices for the specific DIP timeframe
                        const dipTimeframePrices = this.getPricesInTimeframe(priceHistory, strategy.dipTimeframe);
                        const highestPrice = Math.max(...dipTimeframePrices.map(p => p.price));
                        const currentDrop = ((highestPrice - currentPrice) / highestPrice) * 100;
                        const dipTriggerPrice = highestPrice * (1 - strategy.dipThreshold / 100);
                        
                        // Add historical context if enabled
                        let historicalContext = '';
                        if (strategy.enableHistoricalComparison && priceHistory.length > 10) {
                            const historical = this.getHistoricalPriceAnalysis(priceHistory, currentPrice, strategy.historicalTimeframes);
                            historicalContext = ` | ${historical.summary}`;
                        }
                        
                        console.log(`⏳ ${strategy.name}: Waiting for DIP | Current: ${currentPrice.toFixed(8)} | Need: ≤${dipTriggerPrice.toFixed(8)} | Drop: ${currentDrop.toFixed(2)}%/${strategy.dipThreshold}% (${strategy.dipTimeframeLabel})${historicalContext} | Runtime: ${timeRunning}s`);
                    } else {
                        console.log(`📊 ${strategy.name}: Building price history (${priceHistory.length}/2) | Current: ${currentPrice.toFixed(8)} WLD | Runtime: ${timeRunning}s`);
                    }
                } else {
                    // Show brief position status
                    const totalWLD = openPositions.reduce((sum, pos) => sum + pos.entryAmountWLD, 0);
                    const totalTokens = openPositions.reduce((sum, pos) => sum + pos.entryAmountToken, 0);
                    const averagePrice = totalWLD / totalTokens;
                    const targetPrice = averagePrice * (1 + strategy.profitTarget / 100);
                    const priceVsAverage = ((currentPrice - averagePrice) / averagePrice) * 100;
                    
                    const buyStatus = currentPrice <= averagePrice ? '✅ WILL BUY' : '⏳ HOLD ONLY';
                    const sellStatus = currentPrice >= targetPrice ? '🚀 SELL NOW' : `📈 Need +${(((targetPrice - currentPrice) / currentPrice) * 100).toFixed(1)}%`;
                    
                    console.log(`💼 ${strategy.name}: ${openPositions.length} pos | Avg: ${averagePrice.toFixed(8)} | Current: ${currentPrice.toFixed(8)} (${priceVsAverage >= 0 ? '+' : ''}${priceVsAverage.toFixed(1)}%) | ${buyStatus} | ${sellStatus}`);
                }
            }
            
            // Detailed status update (every 10 checks = ~50 seconds)
            if (activeState.checksPerformed % 10 === 0) {
                console.log(`\n📊 STRATEGY STATUS: ${strategy.name}`);
                console.log(`════════════════════════════════════════════════════════════`);
                console.log(`   🔄 Checks Performed: ${activeState.checksPerformed}`);
                console.log(`   💰 Open Positions: ${openPositions.length}`);
                console.log(`   📈 Current Price: ${currentPrice.toFixed(8)} WLD per ${strategy.targetTokenSymbol}`);
                
                if (openPositions.length === 0) {
                    // No positions yet - show DIP detection status
                    console.log(`   🎯 WAITING FOR INITIAL DIP BUY:`);
                    
                    if (priceHistory.length >= 2) {
                        const highestPrice = Math.max(...priceHistory.map(p => p.price));
                        const currentDrop = ((highestPrice - currentPrice) / highestPrice) * 100;
                        const remainingDrop = strategy.dipThreshold - currentDrop;
                        const dipTriggerPrice = highestPrice * (1 - strategy.dipThreshold / 100);
                        
                        console.log(`   📊 Highest Price (${strategy.dipTimeframe/1000}s): ${highestPrice.toFixed(8)} WLD`);
                        console.log(`   📉 DIP Trigger Price: ${dipTriggerPrice.toFixed(8)} WLD (${strategy.dipThreshold}% drop)`);
                        console.log(`   📈 Current Drop: ${currentDrop.toFixed(2)}%`);
                        
                        if (remainingDrop > 0) {
                            console.log(`   ⏳ Need ${remainingDrop.toFixed(2)}% MORE drop to trigger initial buy`);
                            console.log(`   🎯 Waiting for price ≤ ${dipTriggerPrice.toFixed(8)} WLD`);
                        } else {
                            console.log(`   ✅ DIP threshold REACHED! Checking buy conditions...`);
                        }
                    } else {
                        console.log(`   📊 Building price history... (${priceHistory.length}/2 data points needed)`);
                        console.log(`   ⏳ Monitoring for ${strategy.dipTimeframe/1000}s to detect price patterns`);
                    }
                } else {
                    // Show average price strategy status
                    const totalWLD = openPositions.reduce((sum, pos) => sum + pos.entryAmountWLD, 0);
                    const totalTokens = openPositions.reduce((sum, pos) => sum + pos.entryAmountToken, 0);
                    const averagePrice = totalWLD / totalTokens;
                    const targetPrice = averagePrice * (1 + strategy.profitTarget / 100);
                    
                    console.log(`   💼 MANAGING ${openPositions.length} POSITIONS:`);
                    console.log(`   💰 Total Investment: ${totalWLD.toFixed(6)} WLD`);
                    console.log(`   📊 Average Price: ${averagePrice.toFixed(8)} WLD per ${strategy.targetTokenSymbol}`);
                    console.log(`   🎯 Profit Target: ${targetPrice.toFixed(8)} WLD per ${strategy.targetTokenSymbol}`);
                    
                    // Price comparison analysis
                    const priceVsAverage = ((currentPrice - averagePrice) / averagePrice) * 100;
                    const priceVsTarget = ((currentPrice - targetPrice) / targetPrice) * 100;
                    
                    console.log(`   📈 Price vs Average: ${priceVsAverage >= 0 ? '+' : ''}${priceVsAverage.toFixed(2)}%`);
                    
                    if (currentPrice <= averagePrice) {
                        console.log(`   ✅ WILL BUY on next ${strategy.dipThreshold}% DIP (price below average)`);
                        
                        // Show DIP trigger info for additional buys
                        if (priceHistory.length >= 2) {
                            const highestPrice = Math.max(...priceHistory.map(p => p.price));
                            const currentDrop = ((highestPrice - currentPrice) / highestPrice) * 100;
                            const dipTriggerPrice = highestPrice * (1 - strategy.dipThreshold / 100);
                            const remainingDrop = strategy.dipThreshold - currentDrop;
                            
                            if (remainingDrop > 0) {
                                console.log(`   📉 Next DIP buy at: ${dipTriggerPrice.toFixed(8)} WLD (need ${remainingDrop.toFixed(2)}% more drop)`);
                            } else {
                                console.log(`   🚨 DIP DETECTED! Ready to buy more and improve average`);
                            }
                        }
                    } else {
                        console.log(`   ⏳ HOLDING ONLY (price above average - no buying)`);
                        console.log(`   📊 Will buy again when price drops to: ${averagePrice.toFixed(8)} WLD`);
                    }
                    
                    if (currentPrice >= targetPrice) {
                        console.log(`   🚀 PROFIT TARGET REACHED! Will sell ALL positions`);
                        console.log(`   💹 Expected profit: ${priceVsTarget.toFixed(2)}% above target`);
                    } else {
                        const profitNeeded = ((targetPrice - currentPrice) / currentPrice) * 100;
                        console.log(`   📈 Need ${profitNeeded.toFixed(2)}% price increase for profit target`);
                        console.log(`   🎯 Sell trigger: ${targetPrice.toFixed(8)} WLD per ${strategy.targetTokenSymbol}`);
                    }
                }
                
                console.log(`════════════════════════════════════════════════════════════`);
            }
            
        } catch (error) {
            console.error(`❌ Error monitoring strategy ${strategy.name}:`, error.message);
        }
    }
    
    // Helper method to get prices within a specific timeframe
    getPricesInTimeframe(priceHistory, timeframeMs) {
        const cutoffTime = Date.now() - timeframeMs;
        return priceHistory.filter(p => p.timestamp >= cutoffTime);
    }
    
    // Helper method to format time ago
    formatTimeAgo(timestamp) {
        const seconds = Math.floor((Date.now() - timestamp) / 1000);
        
        if (seconds < 60) return `${seconds}s ago`;
        
        const minutes = Math.floor(seconds / 60);
        if (minutes < 60) return `${minutes}m ago`;
        
        const hours = Math.floor(minutes / 60);
        if (hours < 24) return `${hours}h ago`;
        
        const days = Math.floor(hours / 24);
        return `${days}d ago`;
    }
    
    // Get historical price analysis for multiple timeframes
    getHistoricalPriceAnalysis(priceHistory, currentPrice, timeframes) {
        const analysis = {
            periods: {},
            summary: '',
            recommendations: []
        };
        
        for (const [period, timeframeMs] of Object.entries(timeframes)) {
            const periodPrices = this.getPricesInTimeframe(priceHistory, timeframeMs);
            
            if (periodPrices.length > 0) {
                const prices = periodPrices.map(p => p.price);
                const highest = Math.max(...prices);
                const lowest = Math.min(...prices);
                const average = prices.reduce((a, b) => a + b, 0) / prices.length;
                
                const dropFromHigh = ((highest - currentPrice) / highest) * 100;
                const riseFromLow = ((currentPrice - lowest) / lowest) * 100;
                const vsAverage = ((currentPrice - average) / average) * 100;
                
                analysis.periods[period] = {
                    highest,
                    lowest,
                    average,
                    dropFromHigh,
                    riseFromLow,
                    vsAverage,
                    dataPoints: periodPrices.length
                };
                
                // Generate recommendations
                if (dropFromHigh > 10) {
                    analysis.recommendations.push(`Strong DIP vs ${period} high (-${dropFromHigh.toFixed(1)}%)`);
                }
                if (riseFromLow < 5) {
                    analysis.recommendations.push(`Near ${period} low (+${riseFromLow.toFixed(1)}%)`);
                }
            }
        }
        
        // Create summary
        const mainPeriods = ['5min', '1hour', '6hour'];
        const summaryParts = [];
        
        for (const period of mainPeriods) {
            if (analysis.periods[period]) {
                const data = analysis.periods[period];
                if (Math.abs(data.vsAverage) > 2) {
                    const direction = data.vsAverage > 0 ? '+' : '';
                    summaryParts.push(`${period}:${direction}${data.vsAverage.toFixed(1)}%`);
                }
            }
        }
        
        analysis.summary = summaryParts.length > 0 ? summaryParts.join(' ') : 'Near averages';
        
        return analysis;
    }
    
    // Get current price for a token (WLD per token)
    async getCurrentPrice(tokenAddress) {
        if (this.sinclaveEngine) {
            try {
                // Get price using reverse swap quote: 1 token → WLD
                const quote = await this.sinclaveEngine.getHoldStationQuote(
                    tokenAddress,
                    this.WLD_ADDRESS,
                    1, // 1 token
                    '0x0000000000000000000000000000000000000001' // dummy receiver
                );
                
                if (quote && quote.expectedOutput) {
                    return parseFloat(quote.expectedOutput);
                }
            } catch (error) {
                console.log(`⚠️ Enhanced price discovery failed: ${error.message}`);
            }
        }
        
        // Fallback to standard engine
        const priceData = await this.tradingEngine.getTokenPrice(tokenAddress);
        return priceData.price;
    }
    
    // Check for DIP buying opportunity with AVERAGE PRICE PROTECTION
    async checkForDipOpportunity(strategy, priceHistory, currentPrice) {
        if (priceHistory.length < 2) {
            return; // Need at least 2 price points
        }
        
        // Calculate our current average price from existing positions
        const openPositions = strategy.positions.filter(p => p.status === 'open');
        let averagePrice = null;
        
        if (openPositions.length > 0) {
            // Calculate weighted average price from all open positions
            let totalWLD = 0;
            let totalTokens = 0;
            
            openPositions.forEach(pos => {
                totalWLD += pos.entryAmountWLD;
                totalTokens += pos.entryAmountToken;
            });
            
            // Average price = total WLD spent / total tokens received
            averagePrice = totalWLD / totalTokens;
            
            console.log(`📊 Current Average Price: ${averagePrice.toFixed(8)} WLD per token`);
            console.log(`📊 Current Market Price: ${currentPrice.toFixed(8)} WLD per token`);
            
            // CRITICAL: Only buy if current price is AT OR BELOW our average price
            if (currentPrice > averagePrice) {
                console.log(`⚠️  Price Protection: Current price (${currentPrice.toFixed(8)}) is HIGHER than average (${averagePrice.toFixed(8)})`);
                console.log(`   🚫 NOT buying - we only buy when price is same or lower than our average`);
                console.log(`   📊 We maintain our position and wait for:`);
                console.log(`      • Price to drop to/below average: ${averagePrice.toFixed(8)} WLD`);
                console.log(`      • OR profit target reached: ${(averagePrice * (1 + strategy.profitTarget / 100)).toFixed(8)} WLD`);
                return;
            }
            
            console.log(`✅ Price Protection: Current price (${currentPrice.toFixed(8)}) is LOWER than average (${averagePrice.toFixed(8)})`);
            console.log(`   📉 This will IMPROVE our average price - good DIP buy opportunity!`);
        }
        
        // Get prices within the specific DIP detection timeframe
        const dipTimeframePrices = this.getPricesInTimeframe(priceHistory, strategy.dipTimeframe);
        
        if (dipTimeframePrices.length === 0) {
            return; // No prices in timeframe yet
        }
        
        // Find the highest price in the DIP detection timeframe
        const highestPrice = Math.max(...dipTimeframePrices.map(p => p.price));
        const highestPriceTime = dipTimeframePrices.find(p => p.price === highestPrice).timestamp;
        
        // Calculate percentage drop from highest price in timeframe
        const priceDrop = ((highestPrice - currentPrice) / highestPrice) * 100;
        
        if (priceDrop >= strategy.dipThreshold) {
            console.log(`\n🚨 DIP DETECTED for ${strategy.name}!`);
            console.log(`════════════════════════════════════════════════════════════`);
            console.log(`   📊 DIP Analysis (${strategy.dipTimeframeLabel} timeframe):`);
            console.log(`      📈 Highest Price: ${highestPrice.toFixed(8)} WLD (${this.formatTimeAgo(highestPriceTime)})`);
            console.log(`      📉 Current Price: ${currentPrice.toFixed(8)} WLD`);
            console.log(`      📊 Price Drop: ${priceDrop.toFixed(2)}% (Target: ${strategy.dipThreshold}%)`);
            console.log(`      🎯 DIP Trigger: ${(highestPrice * (1 - strategy.dipThreshold / 100)).toFixed(8)} WLD`);
            console.log(`      📋 Data Points: ${dipTimeframePrices.length} prices in ${strategy.dipTimeframeLabel}`);
            
            if (averagePrice) {
                const avgComparison = ((currentPrice - averagePrice) / averagePrice) * 100;
                console.log(`   📊 Average Price Protection:`);
                console.log(`      📊 Current Average: ${averagePrice.toFixed(8)} WLD`);
                console.log(`      📈 Price vs Average: ${avgComparison >= 0 ? '+' : ''}${avgComparison.toFixed(2)}%`);
                console.log(`      ${currentPrice <= averagePrice ? '✅ APPROVED: Price below average - will improve average' : '❌ BLOCKED: Price above average - maintaining discipline'}`);
            } else {
                console.log(`   🎯 Initial Position: No average price yet - first buy opportunity`);
            }
            
            console.log(`   💰 Trade Details:`);
            console.log(`      💵 Amount: ${strategy.tradeAmount} WLD → ${strategy.targetTokenSymbol}`);
            console.log(`      📊 Max Slippage: ${strategy.maxSlippage}%`);
            console.log(`════════════════════════════════════════════════════════════`);
            console.log(`   🚀 Executing DIP buy...`);
            
            await this.executeDipBuy(strategy, currentPrice, averagePrice);
        }
    }
    
    // Execute a DIP buy trade with AVERAGE PRICE TRACKING and LIQUIDITY ANALYSIS
    async executeDipBuy(strategy, entryPrice, previousAveragePrice) {
        try {
            console.log(`🔄 Executing DIP buy: ${strategy.tradeAmount} WLD → ${strategy.targetTokenSymbol}`);
            
            // Analyze liquidity depth to optimize trade amount
            console.log(`🔍 Checking liquidity depth for optimal trade size...`);
            const liquidityAnalysis = await this.sinclaveEngine.analyzeLiquidityDepth(
                this.WLD_ADDRESS,
                strategy.targetToken,
                strategy.maxSlippage
            );
            
            // Determine optimal trade amount
            let optimalAmount = strategy.tradeAmount;
            if (liquidityAnalysis.maxAmount < strategy.tradeAmount) {
                console.log(`⚠️  Liquidity Warning: Requested ${strategy.tradeAmount} WLD exceeds optimal amount`);
                console.log(`   📊 Maximum for ${strategy.maxSlippage}% slippage: ${liquidityAnalysis.maxAmount} WLD`);
                console.log(`   🎯 Adjusting trade amount to: ${liquidityAnalysis.maxAmount} WLD`);
                optimalAmount = liquidityAnalysis.maxAmount;
            } else {
                console.log(`✅ Liquidity Check: ${strategy.tradeAmount} WLD is within optimal range`);
                console.log(`   📊 Pool can handle up to: ${liquidityAnalysis.maxAmount} WLD at ${strategy.maxSlippage}% slippage`);
            }
            
            // Execute the trade using Sinclave Enhanced Engine with optimal amount
            const result = await this.sinclaveEngine.executeOptimizedSwap(
                strategy.walletObject,
                this.WLD_ADDRESS,
                strategy.targetToken,
                optimalAmount,
                strategy.maxSlippage
            );
            
            if (result && result.success) {
                const tokensReceived = parseFloat(result.tokensReceived || result.amountOut || 0);
                const actualEntryPrice = optimalAmount / tokensReceived; // Actual price paid (using optimal amount)
                
                // Create position record
                const position = {
                    id: `pos_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                    strategyId: strategy.id,
                    tokenAddress: strategy.targetToken,
                    status: 'open',
                    
                    // Entry data
                    entryPrice: actualEntryPrice, // Use actual executed price
                    entryAmountWLD: optimalAmount, // Use actual amount traded
                    entryAmountToken: tokensReceived,
                    entryTimestamp: Date.now(),
                    entryTxHash: result.transactionHash || result.txHash,
                    
                    // Target data
                    profitTarget: strategy.profitTarget,
                    targetPrice: entryPrice * (1 + strategy.profitTarget / 100),
                    
                    // Performance tracking
                    unrealizedPnL: 0,
                    unrealizedPnLPercent: 0
                };
                
                strategy.positions.push(position);
                strategy.totalTrades++;
                strategy.lastExecuted = Date.now();
                
                // Calculate new average price after this purchase
                const allPositions = strategy.positions.filter(p => p.status === 'open');
                const totalWLD = allPositions.reduce((sum, pos) => sum + pos.entryAmountWLD, 0);
                const totalTokens = allPositions.reduce((sum, pos) => sum + pos.entryAmountToken, 0);
                const newAveragePrice = totalWLD / totalTokens;
                const newTargetPrice = newAveragePrice * (1 + strategy.profitTarget / 100);
                
                console.log(`✅ DIP buy executed successfully!`);
                console.log(`   📊 Position: ${position.id}`);
                console.log(`   💰 Entry: ${optimalAmount} WLD → ${position.entryAmountToken.toFixed(6)} tokens`);
                console.log(`   📈 Entry Price: ${actualEntryPrice.toFixed(8)} WLD per token`);
                
                if (optimalAmount !== strategy.tradeAmount) {
                    console.log(`   ⚖️  Liquidity Adjusted: ${strategy.tradeAmount} WLD → ${optimalAmount} WLD`);
                    console.log(`   📊 Reason: Pool liquidity limited for ${strategy.maxSlippage}% slippage`);
                }
                
                if (previousAveragePrice) {
                    console.log(`   📊 Previous Avg: ${previousAveragePrice.toFixed(8)} WLD per token`);
                    console.log(`   📊 New Average: ${newAveragePrice.toFixed(8)} WLD per token`);
                    const improvement = ((previousAveragePrice - newAveragePrice) / previousAveragePrice) * 100;
                    console.log(`   📉 Average improved by: ${improvement.toFixed(2)}%`);
                } else {
                    console.log(`   📊 Initial Average: ${newAveragePrice.toFixed(8)} WLD per token`);
                }
                
                console.log(`   🎯 New Profit Target: ${newTargetPrice.toFixed(8)} WLD per token (${strategy.profitTarget}%)`);
                console.log(`   💼 Total Positions: ${allPositions.length}`);
                console.log(`   💰 Total Investment: ${totalWLD.toFixed(6)} WLD`);
                console.log(`   🧾 TX: ${position.entryTxHash}`);
                
                this.saveStrategies();
                this.emit('dipBuyExecuted', { strategy, position, result });
                
            } else {
                throw new Error('DIP buy execution failed');
            }
            
        } catch (error) {
            console.error(`❌ DIP buy failed for ${strategy.name}:`, error.message);
            this.emit('dipBuyFailed', { strategy, error: error.message });
        }
    }
    
    // Enhanced position monitoring with PROFIT RANGE support
    async checkPositionForProfit(strategy, position) {
        try {
            // Calculate current average price from all open positions
            const openPositions = strategy.positions.filter(p => p.status === 'open');
            let totalWLD = 0;
            let totalTokens = 0;
            
            openPositions.forEach(pos => {
                totalWLD += pos.entryAmountWLD;
                totalTokens += pos.entryAmountToken;
            });
            
            const averagePrice = totalWLD / totalTokens;
            
            // Get current market price using a small test amount
            const testQuote = await this.sinclaveEngine.getHoldStationQuote(
                strategy.targetToken,
                this.WLD_ADDRESS,
                1, // 1 token to get price per token
                strategy.walletObject.address
            );
            
            if (testQuote && testQuote.expectedOutput) {
                const currentPrice = parseFloat(testQuote.expectedOutput); // WLD per token
                
                // Calculate total portfolio value at current price
                const totalCurrentValue = totalTokens * currentPrice;
                const unrealizedPnL = totalCurrentValue - totalWLD;
                const unrealizedPnLPercent = (unrealizedPnL / totalWLD) * 100;
                
                // Update position data
                position.unrealizedPnL = unrealizedPnL;
                position.unrealizedPnLPercent = unrealizedPnLPercent;
                
                if (strategy.enableProfitRange) {
                    // ENHANCED PROFIT RANGE MODE
                    await this.handleProfitRange(strategy, openPositions, currentPrice, averagePrice, totalWLD, totalTokens, unrealizedPnLPercent);
                } else {
                    // LEGACY SIMPLE PROFIT TARGET MODE
                    const targetPrice = averagePrice * (1 + strategy.profitTarget / 100);
                    
                    console.log(`📊 Portfolio Status for ${strategy.name} (Simple Mode):`);
                    console.log(`   📊 Average Price: ${averagePrice.toFixed(8)} WLD per token`);
                    console.log(`   📊 Current Price: ${currentPrice.toFixed(8)} WLD per token`);
                    console.log(`   📊 Target Price: ${targetPrice.toFixed(8)} WLD per token`);
                    console.log(`   💰 Total Investment: ${totalWLD.toFixed(6)} WLD`);
                    console.log(`   📈 Current Value: ${totalCurrentValue.toFixed(6)} WLD`);
                    console.log(`   💹 Unrealized P&L: ${unrealizedPnL.toFixed(6)} WLD (${unrealizedPnLPercent.toFixed(2)}%)`);
                    
                    // Check if profit target is reached BASED ON AVERAGE PRICE
                    if (currentPrice >= targetPrice) {
                        console.log(`🎯 PROFIT TARGET REACHED for ${strategy.name}!`);
                        console.log(`   📊 Current price (${currentPrice.toFixed(8)}) >= Target (${targetPrice.toFixed(8)})`);
                        console.log(`   📊 Portfolio profit: ${unrealizedPnLPercent.toFixed(2)}% (Target: ${strategy.profitTarget}%)`);
                        console.log(`   💰 Expected return: ${totalCurrentValue.toFixed(6)} WLD`);
                        console.log(`   🚀 Executing profit sell for ALL positions...`);
                        
                        // Sell ALL positions since we calculate profit based on average
                        await this.executeProfitSellAll(strategy, openPositions, currentPrice);
                    }
                }
            }
            
        } catch (error) {
            console.error(`❌ Error checking position ${position.id}:`, error.message);
        }
    }
    
    // Handle sophisticated profit range selling
    async handleProfitRange(strategy, openPositions, currentPrice, averagePrice, totalWLD, totalTokens, unrealizedPnLPercent) {
        try {
            // Initialize profit range tracking if not exists
            if (!strategy.profitRangeState) {
                strategy.profitRangeState = {
                    sellSteps: [],
                    totalSold: 0,
                    remainingPositions: [...openPositions]
                };
                
                // Calculate sell steps based on range and mode
                this.calculateProfitRangeSteps(strategy);
            }
            
            // Update trigger prices based on current average price
            const rangeState = strategy.profitRangeState;
            rangeState.sellSteps.forEach(step => {
                if (!step.executed) {
                    step.triggerPrice = averagePrice * (1 + step.profitPercent / 100);
                    step.expectedTokens = totalTokens * (step.sellPercentage / 100);
                }
            });
            const minPrice = averagePrice * (1 + strategy.profitRangeMin / 100);
            const maxPrice = averagePrice * (1 + strategy.profitRangeMax / 100);
            
            console.log(`📊 Portfolio Status for ${strategy.name} (Profit Range Mode):`);
            console.log(`   📊 Average Price: ${averagePrice.toFixed(8)} WLD per token`);
            console.log(`   📊 Current Price: ${currentPrice.toFixed(8)} WLD per token`);
            console.log(`   📊 Profit Range: ${strategy.profitRangeMin}% - ${strategy.profitRangeMax}%`);
            console.log(`   📊 Price Range: ${minPrice.toFixed(8)} - ${maxPrice.toFixed(8)} WLD`);
            console.log(`   💰 Total Investment: ${totalWLD.toFixed(6)} WLD`);
            console.log(`   📈 Current Value: ${(totalTokens * currentPrice).toFixed(6)} WLD`);
            console.log(`   💹 Unrealized P&L: ${unrealizedPnLPercent.toFixed(2)}%`);
            
            // Check if we're in the profit range
            if (currentPrice >= minPrice) {
                console.log(`🎯 ENTERED PROFIT RANGE for ${strategy.name}!`);
                
                // Find which sell step we should execute
                const applicableSteps = rangeState.sellSteps.filter(step => 
                    currentPrice >= step.triggerPrice && !step.executed
                );
                
                if (applicableSteps.length > 0) {
                    // Execute the highest applicable step
                    const stepToExecute = applicableSteps.sort((a, b) => b.triggerPrice - a.triggerPrice)[0];
                    
                    console.log(`📊 Executing Profit Range Step ${stepToExecute.stepNumber}:`);
                    console.log(`   📈 Trigger: ${stepToExecute.profitPercent}% (${stepToExecute.triggerPrice.toFixed(8)} WLD)`);
                    console.log(`   💰 Sell Amount: ${stepToExecute.sellPercentage}% of remaining positions`);
                    console.log(`   🎯 Expected: ${stepToExecute.expectedTokens.toFixed(6)} tokens`);
                    
                    await this.executeProfitRangeStep(strategy, stepToExecute, currentPrice);
                } else {
                    // Show range progress
                    const rangeProgress = Math.min(100, ((currentPrice - minPrice) / (maxPrice - minPrice)) * 100);
                    console.log(`   📊 Range Progress: ${rangeProgress.toFixed(1)}% through profit range`);
                    
                    const nextStep = rangeState.sellSteps.find(step => !step.executed);
                    if (nextStep) {
                        console.log(`   ⏳ Next Sell: ${nextStep.profitPercent}% at ${nextStep.triggerPrice.toFixed(8)} WLD`);
                    }
                }
            } else {
                // Show how close we are to profit range
                const progressToRange = ((currentPrice - averagePrice) / (minPrice - averagePrice)) * 100;
                console.log(`   ⏳ Progress to Range: ${Math.max(0, progressToRange).toFixed(1)}% (need ${((minPrice - currentPrice) / currentPrice * 100).toFixed(2)}% more)`);
            }
            
        } catch (error) {
            console.error(`❌ Error handling profit range:`, error.message);
        }
    }
    
    // Calculate profit range sell steps
    calculateProfitRangeSteps(strategy) {
        const rangeState = strategy.profitRangeState;
        const steps = strategy.profitRangeSteps;
        const minPercent = strategy.profitRangeMin;
        const maxPercent = strategy.profitRangeMax;
        
        rangeState.sellSteps = [];
        
        for (let i = 0; i < steps; i++) {
            let profitPercent, sellPercentage;
            
            // Calculate profit percentage for this step
            if (strategy.profitRangeMode === 'linear') {
                // Even distribution across range
                profitPercent = minPercent + (maxPercent - minPercent) * (i + 1) / steps;
                sellPercentage = 100 / steps; // Sell equal portions
            } else if (strategy.profitRangeMode === 'aggressive') {
                // More selling early in the range
                profitPercent = minPercent + (maxPercent - minPercent) * Math.pow((i + 1) / steps, 0.5);
                sellPercentage = i === 0 ? 50 : (100 - 50) / (steps - 1); // 50% first, then split remainder
            } else if (strategy.profitRangeMode === 'conservative') {
                // More selling later in the range
                profitPercent = minPercent + (maxPercent - minPercent) * Math.pow((i + 1) / steps, 2);
                sellPercentage = i === steps - 1 ? 50 : (100 - 50) / (steps - 1); // Split most, 50% at end
            }
            
            const step = {
                stepNumber: i + 1,
                profitPercent: profitPercent,
                triggerPrice: 0, // Will be calculated when positions exist
                sellPercentage: sellPercentage,
                expectedTokens: 0, // Will be calculated when positions exist
                executed: false,
                executedAt: null,
                actualTokensSold: 0,
                actualWLDReceived: 0
            };
            
            rangeState.sellSteps.push(step);
        }
        
        console.log(`📊 Profit Range Steps Calculated (${strategy.profitRangeMode} mode):`);
        rangeState.sellSteps.forEach(step => {
            console.log(`   Step ${step.stepNumber}: ${step.profitPercent.toFixed(1)}% profit → Sell ${step.sellPercentage.toFixed(1)}%`);
        });
    }
    
    // Execute a specific profit range step
    async executeProfitRangeStep(strategy, step, currentPrice) {
        try {
            const openPositions = strategy.positions.filter(p => p.status === 'open');
            const totalTokens = openPositions.reduce((sum, pos) => sum + pos.entryAmountToken, 0);
            const tokensToSell = totalTokens * (step.sellPercentage / 100);
            
            console.log(`🚀 Executing Profit Range Step ${step.stepNumber}...`);
            console.log(`   📊 Selling ${tokensToSell.toFixed(6)} tokens (${step.sellPercentage}% of ${totalTokens.toFixed(6)})`);
            
            // Execute the partial sell
            const sellResult = await this.sinclaveEngine.executeOptimizedSwap(
                strategy.walletObject,
                strategy.targetToken,
                this.WLD_ADDRESS,
                tokensToSell,
                strategy.maxSlippage
            );
            
            if (sellResult.success) {
                step.executed = true;
                step.executedAt = Date.now();
                step.actualTokensSold = tokensToSell;
                step.actualWLDReceived = parseFloat(sellResult.amountOut);
                
                // Update positions proportionally
                const sellRatio = tokensToSell / totalTokens;
                openPositions.forEach(pos => {
                    const soldFromPosition = pos.entryAmountToken * sellRatio;
                    pos.entryAmountToken -= soldFromPosition;
                    pos.entryAmountWLD -= pos.entryAmountWLD * sellRatio;
                    
                    if (pos.entryAmountToken < 0.000001) {
                        pos.status = 'closed';
                        pos.exitPrice = currentPrice;
                        pos.exitTimestamp = Date.now();
                    }
                });
                
                // Update strategy stats
                strategy.totalTrades++;
                strategy.successfulTrades++;
                strategy.totalProfit += step.actualWLDReceived - (tokensToSell / currentPrice); // Approximate profit
                
                console.log(`✅ Profit Range Step ${step.stepNumber} Executed Successfully!`);
                console.log(`   💰 Sold: ${step.actualTokensSold.toFixed(6)} tokens`);
                console.log(`   💰 Received: ${step.actualWLDReceived.toFixed(6)} WLD`);
                console.log(`   📊 Remaining Positions: ${openPositions.filter(p => p.status === 'open').length}`);
                
                this.saveStrategies();
                
            } else {
                console.log(`❌ Profit Range Step ${step.stepNumber} Failed: ${sellResult.error}`);
            }
            
        } catch (error) {
            console.error(`❌ Error executing profit range step:`, error.message);
        }
    }
    
    // Execute profit sell for ALL positions (based on average price strategy)
    async executeProfitSellAll(strategy, positions, currentPrice) {
        try {
            // Calculate total tokens to sell
            let totalTokensToSell = 0;
            positions.forEach(pos => {
                totalTokensToSell += pos.entryAmountToken;
            });
            
            console.log(`🔄 Executing profit sell: ${totalTokensToSell} ${strategy.targetTokenSymbol} → WLD`);
            console.log(`   📊 Selling ${positions.length} positions at average profit target`);
            
            // Execute the reverse trade for ALL tokens
            const result = await this.sinclaveEngine.executeOptimizedSwap(
                strategy.walletObject,
                strategy.targetToken,
                this.WLD_ADDRESS,
                totalTokensToSell,
                strategy.maxSlippage
            );
            
            if (result && result.success) {
                const wldReceived = parseFloat(result.tokensReceived || result.amountOut || 0);
                const totalInvested = positions.reduce((sum, pos) => sum + pos.entryAmountWLD, 0);
                const realizedPnL = wldReceived - totalInvested;
                const realizedPnLPercent = (realizedPnL / totalInvested) * 100;
                
                // Mark ALL positions as closed
                positions.forEach(pos => {
                    pos.status = 'closed';
                    pos.exitPrice = currentPrice;
                    pos.exitAmountWLD = (pos.entryAmountWLD / totalInvested) * wldReceived; // Proportional
                    pos.exitTimestamp = Date.now();
                    pos.exitTxHash = result.transactionHash || result.txHash;
                    pos.realizedPnL = pos.exitAmountWLD - pos.entryAmountWLD;
                    pos.realizedPnLPercent = (pos.realizedPnL / pos.entryAmountWLD) * 100;
                });
                
                // Update strategy statistics
                strategy.successfulTrades++;
                strategy.totalProfit += realizedPnL;
                strategy.lastExecuted = Date.now();
                
                console.log(`✅ Profit sell executed successfully!`);
                console.log(`   📊 Sold: ${totalTokensToSell} tokens → ${wldReceived.toFixed(6)} WLD`);
                console.log(`   💰 Total Invested: ${totalInvested.toFixed(6)} WLD`);
                console.log(`   💹 Realized P&L: ${realizedPnL.toFixed(6)} WLD (${realizedPnLPercent.toFixed(2)}%)`);
                console.log(`   🧾 TX: ${result.transactionHash || result.txHash}`);
                
                this.saveStrategies();
                this.emit('profitSellExecuted', { strategy, positions, result, realizedPnL });
                
            } else {
                throw new Error('Profit sell execution failed');
            }
            
        } catch (error) {
            console.error(`❌ Profit sell failed for ${strategy.name}:`, error.message);
            this.emit('profitSellFailed', { strategy, error: error.message });
        }
    }

    // Execute profit sell (legacy - keeping for compatibility)
    async executeProfitSell(strategy, position, expectedWLDReturn) {
        try {
            console.log(`🔄 Executing profit sell: ${position.entryAmountToken} ${strategy.targetTokenSymbol} → WLD`);
            
            // Execute the reverse trade
            const result = await this.sinclaveEngine.executeOptimizedSwap(
                strategy.walletObject,
                strategy.targetToken,
                this.WLD_ADDRESS,
                position.entryAmountToken,
                strategy.maxSlippage
            );
            
            if (result && result.success) {
                const actualWLDReceived = parseFloat(result.tokensReceived || result.amountOut || 0);
                const realizedPnL = actualWLDReceived - position.entryAmountWLD;
                const realizedPnLPercent = (realizedPnL / position.entryAmountWLD) * 100;
                
                // Update position
                position.status = 'closed';
                position.exitTimestamp = Date.now();
                position.exitTxHash = result.transactionHash || result.txHash;
                position.exitAmountWLD = actualWLDReceived;
                position.realizedPnL = realizedPnL;
                position.realizedPnLPercent = realizedPnLPercent;
                
                // Update strategy stats
                strategy.successfulTrades++;
                strategy.totalProfit += realizedPnL;
                
                console.log(`✅ Profit sell executed successfully!`);
                console.log(`   💰 Return: ${actualWLDReceived.toFixed(6)} WLD`);
                console.log(`   📊 Profit: ${realizedPnL.toFixed(6)} WLD (${realizedPnLPercent.toFixed(2)}%)`);
                console.log(`   🧾 TX: ${position.exitTxHash}`);
                
                this.saveStrategies();
                this.emit('profitSellExecuted', { strategy, position, result });
                
            } else {
                throw new Error('Profit sell execution failed');
            }
            
        } catch (error) {
            console.error(`❌ Profit sell failed for position ${position.id}:`, error.message);
            this.emit('profitSellFailed', { strategy, position, error: error.message });
        }
    }
    
    // Get all strategies
    getAllStrategies() {
        return Array.from(this.customStrategies.values());
    }
    
    // Check if a strategy is active
    isStrategyActive(strategyId) {
        const strategy = this.customStrategies.get(strategyId);
        return strategy && strategy.isActive === true;
    }
    
    // Get strategy by ID
    getStrategy(strategyId) {
        return this.customStrategies.get(strategyId);
    }
    
    // Delete strategy
    deleteStrategy(strategyId) {
        const strategy = this.customStrategies.get(strategyId);
        if (!strategy) {
            throw new Error(`Strategy ${strategyId} not found`);
        }
        
        // Stop if active
        if (strategy.isActive) {
            this.stopStrategy(strategyId);
        }
        
        this.customStrategies.delete(strategyId);
        this.saveStrategies();
        
        console.log(`🗑️ Deleted strategy: ${strategy.name}`);
        return true;
    }
    
    // Save strategies to file
    saveStrategies() {
        try {
            const strategiesData = {};
            for (const [id, strategy] of this.customStrategies.entries()) {
                // Don't save wallet object (contains private key)
                const { walletObject, ...safeStrategy } = strategy;
                strategiesData[id] = safeStrategy;
            }
            
            fs.writeFileSync(this.strategiesPath, JSON.stringify(strategiesData, null, 2));
        } catch (error) {
            console.error('❌ Error saving strategies:', error.message);
        }
    }
    
    // Load strategies from file
    loadStrategies() {
        try {
            if (fs.existsSync(this.strategiesPath)) {
                const strategiesData = JSON.parse(fs.readFileSync(this.strategiesPath, 'utf8'));
                for (const [id, strategy] of Object.entries(strategiesData)) {
                    this.customStrategies.set(id, strategy);
                }
                console.log(`📂 Loaded ${Object.keys(strategiesData).length} custom strategies`);
            }
        } catch (error) {
            console.error('❌ Error loading strategies:', error.message);
        }
    }
    
    // Get strategy statistics
    getStrategyStatistics() {
        const strategies = this.getAllStrategies();
        const activeStrategies = strategies.filter(s => s.isActive);
        const totalTrades = strategies.reduce((sum, s) => sum + s.totalTrades, 0);
        const successfulTrades = strategies.reduce((sum, s) => sum + s.successfulTrades, 0);
        const totalProfit = strategies.reduce((sum, s) => sum + s.totalProfit, 0);
        
        return {
            totalStrategies: strategies.length,
            activeStrategies: activeStrategies.length,
            totalTrades,
            successfulTrades,
            successRate: totalTrades > 0 ? (successfulTrades / totalTrades * 100).toFixed(2) : '0.00',
            totalProfit: totalProfit.toFixed(6),
            strategies: strategies.map(s => ({
                id: s.id,
                name: s.name,
                tokenSymbol: s.tokenSymbol,
                isActive: s.isActive,
                totalTrades: s.totalTrades,
                successfulTrades: s.successfulTrades,
                totalProfit: s.totalProfit.toFixed(6),
                openPositions: s.positions.filter(p => p.status === 'open').length
            }))
        };
    }
}

module.exports = StrategyBuilder;