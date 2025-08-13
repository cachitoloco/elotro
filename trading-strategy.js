const { ethers } = require('ethers');
const EventEmitter = require('events');

class TradingStrategy extends EventEmitter {
    constructor(tradingEngine, config, sinclaveEngine = null) {
        super();
        this.tradingEngine = tradingEngine;
        this.sinclaveEngine = sinclaveEngine; // Enhanced engine for better execution
        this.config = config;
        
        // Strategy configuration with defaults
        this.strategyConfig = {
            // Main strategy settings
            profitTarget: parseFloat(process.env.PROFIT_TARGET) || 1.0, // 1% profit target
            dipBuyThreshold: parseFloat(process.env.DIP_BUY_THRESHOLD) || 1.0, // Buy on 1% dip
            maxSlippage: parseFloat(process.env.MAX_SLIPPAGE) || 1.0, // Max 1% slippage
            
            // Monitoring settings
            priceCheckInterval: parseInt(process.env.PRICE_CHECK_INTERVAL) || 5000, // 5 seconds
            enableDipBuying: process.env.ENABLE_DIP_BUYING === 'true' || false,
            enableAutoSell: process.env.ENABLE_AUTO_SELL === 'true' || true,
            
            // Risk management
            maxPositionSize: parseFloat(process.env.MAX_POSITION_SIZE) || 100, // Max WLD per position
            maxOpenPositions: parseInt(process.env.MAX_OPEN_POSITIONS) || 5,
            stopLossThreshold: parseFloat(process.env.STOP_LOSS_THRESHOLD) || -5.0, // 5% stop loss
            
            // Advanced settings
            trailingStop: parseFloat(process.env.TRAILING_STOP) || 0.5, // 0.5% trailing stop
            enableTrailingStop: process.env.ENABLE_TRAILING_STOP === 'true' || false,
            minProfitForTrailing: parseFloat(process.env.MIN_PROFIT_FOR_TRAILING) || 2.0, // 2% min profit to enable trailing
        };
        
        // Position tracking
        this.positions = new Map(); // tokenAddress -> position data
        this.priceHistory = new Map(); // tokenAddress -> price history array
        this.monitoringIntervals = new Map(); // tokenAddress -> interval ID
        
        // Strategy state
        this.isRunning = false;
        this.totalProfit = 0;
        this.totalTrades = 0;
        this.successfulTrades = 0;
        
        // WLD token address
        this.WLD_ADDRESS = '0x2cfc85d8e48f8eab294be644d9e25c3030863003';
        
        console.log('🎯 Trading Strategy initialized with configuration:', this.strategyConfig);
        if (this.sinclaveEngine) {
            console.log('✅ Sinclave Enhanced Engine available for optimal execution');
        } else {
            console.log('⚠️ Using standard trading engine (consider upgrading to Enhanced)');
        }
    }

    // Start the strategy system
    async startStrategy() {
        if (this.isRunning) {
            console.log('⚠️ Strategy is already running');
            return;
        }
        
        this.isRunning = true;
        console.log('🚀 Starting Trading Strategy System...');
        
        // Load existing positions
        await this.loadPositions();
        
        // Start monitoring existing positions
        for (const [tokenAddress, position] of this.positions) {
            if (position.status === 'open') {
                this.startPositionMonitoring(tokenAddress);
            }
        }
        
        this.emit('strategyStarted');
        console.log('✅ Trading Strategy System is now active');
    }

    // Stop the strategy system
    async stopStrategy() {
        if (!this.isRunning) {
            console.log('⚠️ Strategy is not running');
            return;
        }
        
        this.isRunning = false;
        console.log('🛑 Stopping Trading Strategy System...');
        
        // Stop all monitoring intervals
        for (const [tokenAddress, intervalId] of this.monitoringIntervals) {
            clearInterval(intervalId);
            console.log(`📊 Stopped monitoring ${tokenAddress}`);
        }
        
        this.monitoringIntervals.clear();
        
        // Save positions
        await this.savePositions();
        
        this.emit('strategyStopped');
        console.log('✅ Trading Strategy System stopped');
    }

    // Execute a buy trade and open a position (ENHANCED WITH SINCLAVE ENGINE)
    async executeBuyTrade(wallet, tokenAddress, amountWLD, currentPrice = null) {
        try {
            console.log(`🔄 Executing BUY trade: ${amountWLD} WLD -> ${tokenAddress}`);
            
            // Validate position limits
            if (this.positions.size >= this.strategyConfig.maxOpenPositions) {
                throw new Error(`Maximum open positions (${this.strategyConfig.maxOpenPositions}) reached`);
            }
            
            if (amountWLD > this.strategyConfig.maxPositionSize) {
                throw new Error(`Position size (${amountWLD}) exceeds maximum (${this.strategyConfig.maxPositionSize})`);
            }
            
            // Use Sinclave Enhanced Engine if available for better execution
            let result;
            if (this.sinclaveEngine) {
                console.log('🚀 Using Sinclave Enhanced Engine for optimal execution...');
                
                // Execute with enhanced engine (handles slippage and liquidity checks internally)
                result = await this.sinclaveEngine.executeOptimizedSwap(
                    wallet,
                    this.WLD_ADDRESS,
                    tokenAddress,
                    amountWLD,
                    this.strategyConfig.maxSlippage
                );
                
                if (!result.success) {
                    throw new Error(`Enhanced trade execution failed: ${result.error}`);
                }
                
                console.log(`✅ Enhanced trade completed in ${result.executionTime}ms`);
                
            } else {
                // Fallback to standard engine with price checks
                console.log('⚠️ Using standard trading engine (liquidity may be limited)');
                
                // Get current price quote if not provided
                if (!currentPrice) {
                    const priceData = await this.tradingEngine.getTokenPrice(tokenAddress);
                    currentPrice = priceData.price;
                }
                
                // Check slippage before executing
                const quote = await this.getSwapQuote(this.WLD_ADDRESS, tokenAddress, amountWLD);
                const slippage = this.calculateSlippage(quote.expectedPrice, currentPrice);
                
                if (Math.abs(slippage) > this.strategyConfig.maxSlippage) {
                    throw new Error(`Slippage too high: ${slippage.toFixed(2)}% (max: ${this.strategyConfig.maxSlippage}%)`);
                }
                
                // Execute the trade with standard engine
                result = await this.tradingEngine.executeSwap(
                    wallet,
                    this.WLD_ADDRESS,
                    tokenAddress,
                    amountWLD,
                    this.strategyConfig.maxSlippage
                );
                
                if (!result.success) {
                    throw new Error(`Trade execution failed: ${result.error}`);
                }
            }
            
            // Create position record (works with both engines)
            const calculatedPrice = currentPrice || (result.tokensReceived && result.tokensSpent ? 
                parseFloat(result.tokensSpent) / parseFloat(result.tokensReceived) : 0);
            
            const position = {
                id: `pos_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                tokenAddress: tokenAddress,
                walletAddress: wallet.address,
                status: 'open',
                
                // Entry data
                entryPrice: calculatedPrice,
                entryAmountWLD: parseFloat(amountWLD),
                entryAmountToken: parseFloat(result.amountOut || result.tokensReceived || 0),
                entryTimestamp: Date.now(),
                entryTxHash: result.txHash || result.transactionHash,
                
                // Current data (updated by monitoring)
                currentPrice: calculatedPrice,
                currentValue: parseFloat(amountWLD), // Current value in WLD
                unrealizedPnL: 0,
                unrealizedPnLPercent: 0,
                
                // Strategy data
                profitTarget: this.strategyConfig.profitTarget,
                stopLoss: this.strategyConfig.stopLossThreshold,
                highestPrice: calculatedPrice, // For trailing stop
                trailingStopPrice: null,
                
                // Trade history
                trades: [{
                    type: 'buy',
                    timestamp: Date.now(),
                    price: calculatedPrice,
                    amountWLD: parseFloat(amountWLD),
                    amountToken: parseFloat(result.amountOut || result.tokensReceived || 0),
                    txHash: result.txHash || result.transactionHash,
                    gasUsed: result.gasUsed || 'N/A'
                }]
            };
            
            // Store position
            this.positions.set(tokenAddress, position);
            await this.savePositions();
            
            // Start monitoring this position
            this.startPositionMonitoring(tokenAddress);
            
            // Update statistics
            this.totalTrades++;
            
            console.log(`✅ Position opened: ${position.id}`);
            const tokensReceived = result.amountOut || result.tokensReceived || 'Unknown';
            const priceDisplay = calculatedPrice > 0 ? calculatedPrice.toFixed(8) : 'Unknown';
            console.log(`📊 Entry: ${amountWLD} WLD -> ${tokensReceived} tokens at ${priceDisplay} WLD/token`);
            
            this.emit('positionOpened', position);
            return position;
            
        } catch (error) {
            console.error(`❌ Buy trade failed:`, error.message);
            this.emit('tradeError', { type: 'buy', error: error.message });
            throw error;
        }
    }

    // Execute a sell trade and close a position (ENHANCED WITH SINCLAVE ENGINE)
    async executeSellTrade(tokenAddress, reason = 'manual') {
        try {
            const position = this.positions.get(tokenAddress);
            if (!position || position.status !== 'open') {
                throw new Error('No open position found for this token');
            }
            
            console.log(`🔄 Executing SELL trade: ${position.entryAmountToken} tokens -> WLD (${reason})`);
            
            // We need the full wallet object - this would need to be passed in or retrieved
            const wallet = { address: position.walletAddress }; // This is a limitation - we need the private key
            
            // Use Sinclave Enhanced Engine if available for better execution
            let result;
            if (this.sinclaveEngine) {
                console.log('🚀 Using Sinclave Enhanced Engine for optimal sell execution...');
                
                // Execute with enhanced engine
                result = await this.sinclaveEngine.executeOptimizedSwap(
                    wallet,
                    tokenAddress,
                    this.WLD_ADDRESS,
                    position.entryAmountToken,
                    this.strategyConfig.maxSlippage
                );
                
                if (!result.success) {
                    throw new Error(`Enhanced sell execution failed: ${result.error}`);
                }
                
                console.log(`✅ Enhanced sell completed in ${result.executionTime}ms`);
                
            } else {
                // Fallback to standard engine
                console.log('⚠️ Using standard trading engine for sell (liquidity may be limited)');
                
                // Get current price
                const currentPrice = await this.getCurrentTokenPrice(tokenAddress);
                
                // Execute the sell trade
                result = await this.tradingEngine.executeSwap(
                    wallet,
                    tokenAddress,
                    this.WLD_ADDRESS,
                    position.entryAmountToken,
                    this.strategyConfig.maxSlippage
                );
                
                if (!result.success) {
                    throw new Error(`Sell execution failed: ${result.error}`);
                }
            }
            
            // Calculate final P&L
            const exitAmountWLD = parseFloat(result.amountOut);
            const realizedPnL = exitAmountWLD - position.entryAmountWLD;
            const realizedPnLPercent = (realizedPnL / position.entryAmountWLD) * 100;
            
            // Update position
            position.status = 'closed';
            position.exitPrice = currentPrice;
            position.exitAmountWLD = exitAmountWLD;
            position.exitTimestamp = Date.now();
            position.exitTxHash = result.txHash;
            position.realizedPnL = realizedPnL;
            position.realizedPnLPercent = realizedPnLPercent;
            position.closeReason = reason;
            
            // Add exit trade to history
            position.trades.push({
                type: 'sell',
                timestamp: Date.now(),
                price: currentPrice,
                amountWLD: exitAmountWLD,
                amountToken: position.entryAmountToken,
                txHash: result.txHash,
                gasUsed: result.gasUsed,
                reason: reason
            });
            
            // Stop monitoring
            this.stopPositionMonitoring(tokenAddress);
            
            // Update statistics
            this.totalProfit += realizedPnL;
            if (realizedPnL > 0) {
                this.successfulTrades++;
            }
            
            // Save positions
            await this.savePositions();
            
            console.log(`✅ Position closed: ${position.id}`);
            console.log(`📊 Exit: ${position.entryAmountToken} tokens -> ${exitAmountWLD} WLD at ${currentPrice.toFixed(8)} WLD/token`);
            console.log(`💰 P&L: ${realizedPnL.toFixed(4)} WLD (${realizedPnLPercent.toFixed(2)}%)`);
            
            this.emit('positionClosed', position);
            return position;
            
        } catch (error) {
            console.error(`❌ Sell trade failed:`, error.message);
            this.emit('tradeError', { type: 'sell', error: error.message });
            throw error;
        }
    }

    // Start monitoring a position
    startPositionMonitoring(tokenAddress) {
        if (this.monitoringIntervals.has(tokenAddress)) {
            console.log(`⚠️ Already monitoring ${tokenAddress}`);
            return;
        }
        
        console.log(`📊 Starting price monitoring for ${tokenAddress}`);
        
        const intervalId = setInterval(async () => {
            try {
                await this.monitorPosition(tokenAddress);
            } catch (error) {
                console.error(`❌ Monitoring error for ${tokenAddress}:`, error.message);
            }
        }, this.strategyConfig.priceCheckInterval);
        
        this.monitoringIntervals.set(tokenAddress, intervalId);
    }

    // Stop monitoring a position
    stopPositionMonitoring(tokenAddress) {
        const intervalId = this.monitoringIntervals.get(tokenAddress);
        if (intervalId) {
            clearInterval(intervalId);
            this.monitoringIntervals.delete(tokenAddress);
            console.log(`📊 Stopped monitoring ${tokenAddress}`);
        }
    }

    // Monitor a single position
    async monitorPosition(tokenAddress) {
        const position = this.positions.get(tokenAddress);
        if (!position || position.status !== 'open') {
            this.stopPositionMonitoring(tokenAddress);
            return;
        }
        
        try {
            // Get current price by simulating a sell quote
            const currentPrice = await this.getCurrentTokenPrice(tokenAddress);
            
            // Calculate current position value
            const currentValue = position.entryAmountToken * currentPrice;
            const unrealizedPnL = currentValue - position.entryAmountWLD;
            const unrealizedPnLPercent = (unrealizedPnL / position.entryAmountWLD) * 100;
            
            // Update position data
            position.currentPrice = currentPrice;
            position.currentValue = currentValue;
            position.unrealizedPnL = unrealizedPnL;
            position.unrealizedPnLPercent = unrealizedPnLPercent;
            
            // Update highest price for trailing stop
            if (currentPrice > position.highestPrice) {
                position.highestPrice = currentPrice;
                
                // Update trailing stop price if enabled and profitable enough
                if (this.strategyConfig.enableTrailingStop && 
                    unrealizedPnLPercent >= this.strategyConfig.minProfitForTrailing) {
                    const trailingStopPercent = this.strategyConfig.trailingStop / 100;
                    position.trailingStopPrice = currentPrice * (1 - trailingStopPercent);
                }
            }
            
            // Store price in history
            if (!this.priceHistory.has(tokenAddress)) {
                this.priceHistory.set(tokenAddress, []);
            }
            const history = this.priceHistory.get(tokenAddress);
            history.push({
                timestamp: Date.now(),
                price: currentPrice,
                value: currentValue,
                pnlPercent: unrealizedPnLPercent
            });
            
            // Keep only last 1000 price points
            if (history.length > 1000) {
                history.splice(0, history.length - 1000);
            }
            
            // Check trading conditions
            await this.checkTradingConditions(tokenAddress, position);
            
            // Emit price update event
            this.emit('priceUpdate', {
                tokenAddress,
                position,
                currentPrice,
                unrealizedPnLPercent
            });
            
        } catch (error) {
            console.error(`❌ Error monitoring ${tokenAddress}:`, error.message);
        }
    }

    // Check if trading conditions are met
    async checkTradingConditions(tokenAddress, position) {
        const { unrealizedPnLPercent, currentPrice, trailingStopPrice } = position;
        
        // Check profit target
        if (this.strategyConfig.enableAutoSell && unrealizedPnLPercent >= this.strategyConfig.profitTarget) {
            console.log(`🎯 Profit target reached for ${tokenAddress}: ${unrealizedPnLPercent.toFixed(2)}%`);
            await this.executeSellTrade(tokenAddress, 'profit_target');
            return;
        }
        
        // Check stop loss
        if (unrealizedPnLPercent <= this.strategyConfig.stopLossThreshold) {
            console.log(`🛑 Stop loss triggered for ${tokenAddress}: ${unrealizedPnLPercent.toFixed(2)}%`);
            await this.executeSellTrade(tokenAddress, 'stop_loss');
            return;
        }
        
        // Check trailing stop
        if (this.strategyConfig.enableTrailingStop && trailingStopPrice && 
            currentPrice <= trailingStopPrice) {
            console.log(`📉 Trailing stop triggered for ${tokenAddress}: ${currentPrice.toFixed(8)} <= ${trailingStopPrice.toFixed(8)}`);
            await this.executeSellTrade(tokenAddress, 'trailing_stop');
            return;
        }
        
        // Check DIP buying opportunity (if enabled and we don't have a position)
        if (this.strategyConfig.enableDipBuying) {
            await this.checkDipBuyingOpportunity(tokenAddress);
        }
    }

    // Check for DIP buying opportunities
    async checkDipBuyingOpportunity(tokenAddress) {
        try {
            // Get price history for this token
            const history = this.priceHistory.get(tokenAddress);
            if (!history || history.length < 10) {
                return; // Need more price data
            }
            
            // Calculate average price over last 10 data points
            const recentPrices = history.slice(-10);
            const avgPrice = recentPrices.reduce((sum, item) => sum + item.price, 0) / recentPrices.length;
            const currentPrice = history[history.length - 1].price;
            
            // Check if current price is a dip
            const dipPercent = ((avgPrice - currentPrice) / avgPrice) * 100;
            
            if (dipPercent >= this.strategyConfig.dipBuyThreshold) {
                console.log(`📉 DIP detected for ${tokenAddress}: ${dipPercent.toFixed(2)}% below average`);
                
                // Emit DIP opportunity event (let the user decide)
                this.emit('dipOpportunity', {
                    tokenAddress,
                    currentPrice,
                    avgPrice,
                    dipPercent
                });
            }
            
        } catch (error) {
            console.error(`❌ Error checking DIP opportunity for ${tokenAddress}:`, error.message);
        }
    }

    // Get current token price by simulating a sell quote (ENHANCED)
    async getCurrentTokenPrice(tokenAddress) {
        try {
            // Use Sinclave Enhanced Engine for better price discovery if available
            if (this.sinclaveEngine) {
                try {
                    // Use HoldStation SDK for accurate price discovery
                    const quote = await this.sinclaveEngine.getHoldStationQuote(
                        tokenAddress, 
                        this.WLD_ADDRESS, 
                        1, // 1 token
                        '0x0000000000000000000000000000000000000001' // dummy receiver
                    );
                    
                    if (quote && quote.expectedOutput) {
                        const price = parseFloat(quote.expectedOutput);
                        return price > 0 ? price : 0;
                    }
                } catch (enhancedError) {
                    console.log(`⚠️ Enhanced price discovery failed: ${enhancedError.message}`);
                    // Fall back to standard method
                }
            }
            
            // Fallback to standard quote method
            const quote = await this.getSwapQuote(tokenAddress, this.WLD_ADDRESS, 1);
            return quote.pricePerToken;
        } catch (error) {
            console.error(`❌ Error getting current price for ${tokenAddress}:`, error.message);
            throw new Error(`No liquidity found for this pair`);
        }
    }

    // Get swap quote (ENHANCED WITH FALLBACK)
    async getSwapQuote(tokenIn, tokenOut, amountIn) {
        try {
            // Try enhanced engine first if available
            if (this.sinclaveEngine) {
                try {
                    const quote = await this.sinclaveEngine.getHoldStationQuote(
                        tokenIn, 
                        tokenOut, 
                        amountIn, 
                        '0x0000000000000000000000000000000000000001' // dummy receiver
                    );
                    
                    if (quote && quote.expectedOutput) {
                        const expectedOutput = parseFloat(quote.expectedOutput);
                        const pricePerToken = tokenOut === this.WLD_ADDRESS ? expectedOutput / amountIn : amountIn / expectedOutput;
                        
                        return {
                            amountIn,
                            expectedOutput,
                            pricePerToken,
                            expectedPrice: pricePerToken,
                            fee: 0.2, // HoldStation fee
                            slippage: 0.5, // Default slippage
                            provider: 'HoldStation'
                        };
                    }
                } catch (enhancedError) {
                    console.log(`⚠️ Enhanced quote failed: ${enhancedError.message}, using fallback`);
                }
            }
            
            // Fallback to standard engine
            const priceData = await this.tradingEngine.getTokenPrice(tokenOut);
            
            // Calculate expected output
            const expectedOutput = amountIn * priceData.price;
            const pricePerToken = tokenOut === this.WLD_ADDRESS ? priceData.price : 1 / priceData.price;
            
            return {
                amountIn,
                expectedOutput,
                pricePerToken,
                expectedPrice: priceData.price,
                fee: priceData.fee,
                slippage: 0, // Would be calculated based on liquidity
                provider: 'Uniswap'
            };
        } catch (error) {
            throw new Error(`Quote failed: ${error.message}`);
        }
    }

    // Calculate slippage
    calculateSlippage(expectedPrice, actualPrice) {
        return ((expectedPrice - actualPrice) / expectedPrice) * 100;
    }

    // Get strategy statistics
    getStrategyStats() {
        const openPositions = Array.from(this.positions.values()).filter(p => p.status === 'open');
        const closedPositions = Array.from(this.positions.values()).filter(p => p.status === 'closed');
        
        const totalUnrealizedPnL = openPositions.reduce((sum, pos) => sum + pos.unrealizedPnL, 0);
        const totalRealizedPnL = closedPositions.reduce((sum, pos) => sum + pos.realizedPnL, 0);
        
        return {
            isRunning: this.isRunning,
            totalPositions: this.positions.size,
            openPositions: openPositions.length,
            closedPositions: closedPositions.length,
            totalTrades: this.totalTrades,
            successfulTrades: this.successfulTrades,
            successRate: this.totalTrades > 0 ? (this.successfulTrades / this.totalTrades) * 100 : 0,
            totalUnrealizedPnL,
            totalRealizedPnL,
            totalPnL: totalUnrealizedPnL + totalRealizedPnL,
            config: this.strategyConfig
        };
    }

    // Get all positions
    getAllPositions() {
        return Array.from(this.positions.values());
    }

    // Get position by token address
    getPosition(tokenAddress) {
        return this.positions.get(tokenAddress);
    }

    // Update strategy configuration
    updateConfig(newConfig) {
        this.strategyConfig = { ...this.strategyConfig, ...newConfig };
        console.log('⚙️ Strategy configuration updated:', newConfig);
        this.emit('configUpdated', this.strategyConfig);
    }

    // Save positions to file
    async savePositions() {
        try {
            const fs = require('fs');
            const path = require('path');
            
            const positionsData = {
                positions: Object.fromEntries(this.positions),
                priceHistory: Object.fromEntries(this.priceHistory),
                stats: this.getStrategyStats(),
                lastUpdated: new Date().toISOString()
            };
            
            const filePath = path.join(__dirname, 'strategy_positions.json');
            fs.writeFileSync(filePath, JSON.stringify(positionsData, null, 2));
            
        } catch (error) {
            console.error('❌ Error saving positions:', error.message);
        }
    }

    // Load positions from file
    async loadPositions() {
        try {
            const fs = require('fs');
            const path = require('path');
            const filePath = path.join(__dirname, 'strategy_positions.json');
            
            if (fs.existsSync(filePath)) {
                const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
                
                if (data.positions) {
                    this.positions = new Map(Object.entries(data.positions));
                }
                
                if (data.priceHistory) {
                    this.priceHistory = new Map(Object.entries(data.priceHistory));
                }
                
                console.log(`📊 Loaded ${this.positions.size} positions from storage`);
            }
            
        } catch (error) {
            console.error('❌ Error loading positions:', error.message);
        }
    }

    // Close all open positions
    async closeAllPositions(reason = 'manual_close_all') {
        const openPositions = Array.from(this.positions.values()).filter(p => p.status === 'open');
        
        console.log(`🔄 Closing ${openPositions.length} open positions...`);
        
        for (const position of openPositions) {
            try {
                await this.executeSellTrade(position.tokenAddress, reason);
                console.log(`✅ Closed position for ${position.tokenAddress}`);
            } catch (error) {
                console.error(`❌ Failed to close position for ${position.tokenAddress}:`, error.message);
            }
        }
        
        console.log('✅ All positions closed');
    }
}

module.exports = TradingStrategy;