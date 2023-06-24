


#define MAGICMA  20131111
//--- Inputs
input double Lots          =0.1; // may select it from 0.01
input double MaximumRisk   =0.02; // risk is only 2%, this is highly advised
input double DecreaseFactor=3;
input int    MovingPeriod  =12;
input int    MovingShift   =6;
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   double ma;
   int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//--- sell conditions
   if(Open[1]>ma && Close[1]<ma)
     {
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
      return;
     }
//--- buy conditions
   if(Open[1]<ma && Close[1]>ma)
     {
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   double ma;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(Open[1]>ma && Close[1]<ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(Open[1]<ma && Close[1]>ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
//---
  }



Explanation of code line by line

1. `#define MAGICMA 20131111`: This line defines a preprocessor constant `MAGICMA` with the value 20131111.

3. `input double Lots = 0.1;`: This line declares an input variable `Lots` of type double and assigns it a default value of 0.1.

5. `input double MaximumRisk = 0.02;`: This line declares an input variable `MaximumRisk` of type double and assigns it a default value of 0.02.

7. `input double DecreaseFactor = 3;`: This line declares an input variable `DecreaseFactor` of type double and assigns it a default value of 3.

9. `input int MovingPeriod = 12;`: This line declares an input variable `MovingPeriod` of type int and assigns it a default value of 12.

11. `input int MovingShift = 6;`: This line declares an input variable `MovingShift` of type int and assigns it a default value of 6.

15. `int CalculateCurrentOrders(string symbol)`: This line defines a function named `CalculateCurrentOrders` that takes a string parameter `symbol` and returns an integer value. This function is used to calculate the number of open positions (buys or sells) for the given symbol.

17. `int buys = 0, sells = 0;`: This line declares two integer variables `buys` and `sells` and initializes them to 0. These variables will store the count of buy and sell orders.

21. `for (int i = 0; i < OrdersTotal(); i++)`: This line starts a for loop that iterates over all orders using the `OrdersTotal()` function to get the total number of orders.

23. `if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;`: This line selects the order at the current iteration index using the `OrderSelect()` function. If the function call returns false, it means there was an error in selecting the order, so the loop is terminated using `break`.

25. `if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICMA)`: This line checks if the selected order's symbol matches the current symbol being traded and if the order's magic number matches the predefined `MAGICMA` value.

27. `if (OrderType() == OP_BUY) buys++;`: This line increments the `buys` variable if the order type is a buy order.

28. `if (OrderType() == OP_SELL) sells++;`: This line increments the `sells` variable if the order type is a sell order.

34. `if (buys > 0) return (buys);`: This line checks if there are any buy orders and returns the count of buy orders.

36. `else return (-sells);`: This line executes if there are no buy orders, and it returns the negative count of sell orders.

40. `double LotsOptimized()`: This line defines a function named `LotsOptimized` that returns a double value. This function calculates the optimal lot size based on the account's free margin and the risk parameters.

42. `double lot = Lots;`: This line declares a double variable `lot` and initializes it with the value of the input variable `Lots`.

43. `int orders = HistoryTotal();`: This line declares an integer variable `orders` and assigns it the total number of historical orders using the `HistoryTotal()` function.

44. `int losses = 0;`: This line declares an integer variable `losses` and initializes it

 to 0. This variable will store the count of consecutive losing orders.

48. `lot = NormalizeDouble(AccountFreeMargin() * MaximumRisk / 1000.0, 1);`: This line calculates the lot size based on the account's free margin and the maximum risk percentage. The `NormalizeDouble()` function is used to round the lot size to one decimal place.

54. `for (int i = orders - 1; i >= 0; i--)`: This line starts a loop that iterates backward over the historical orders starting from the most recent order.

56. `if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false)`: This line selects the historical order at the current iteration index. If the selection fails, it prints an error message and breaks the loop.

58. `if (OrderSymbol() != Symbol() || OrderType() > OP_SELL) continue;`: This line skips the current iteration if the order's symbol does not match the current symbol being traded or if the order type is not a sell order.

62. `if (OrderProfit() > 0) break;`: This line breaks the loop if the order's profit is greater than 0, indicating a winning order.

64. `if (OrderProfit() < 0) losses++;`: This line increments the `losses` variable if the order's profit is less than 0, indicating a losing order.

68. `if (losses > 1) lot = NormalizeDouble(lot - lot * losses / DecreaseFactor, 1);`: This line adjusts the lot size if there are more than one consecutive losing orders. It decreases the lot size by a factor based on the `DecreaseFactor` input value.

74. `if (lot < 0.1) lot = 0.1;`: This line checks if the calculated lot size is less than 0.1 and sets it to 0.1 if it is.

77. `return (lot);`: This line returns the final calculated lot size.

81. `void CheckForOpen()`: This line defines a void function named `CheckForOpen` that checks for conditions to open new orders.

83. `double ma;`: This line declares a double variable `ma` that will store the moving average value.

85. `int res;`: This line declares an integer variable `res` that will store the result of the `OrderSend()` function call.

90. `if (Volume[0] > 1) return;`: This line checks if the current tick volume is greater than 1. If so, it returns, skipping the rest of the function execution. This is to ensure that the function is executed only on the first ticks of a new bar.

93. `ma = iMA(NULL, 0, MovingPeriod, MovingShift, MODE_SMA, PRICE_CLOSE, 0);`: This line calculates the moving average using the `iMA()` function with the specified parameters.

97. `if (Open[1] > ma && Close[1] < ma)`: This line checks if the previous bar's open price is greater than the moving average and the previous bar's close price is less than the moving average.

99. `res = OrderSend(Symbol(), OP_SELL, LotsOptimized(), Bid, 3, 0, 0, "", MAGICMA, 0, Red);`: This line sends a sell order using the `OrderSend()` function with the specified parameters. It assigns the result to the `res` variable.

105. `if (Open[1] < ma && Close[1] > ma)`: This line checks if the previous bar's open price is less than the

 moving average and the previous bar's close price is greater than the moving average.

107. `res = OrderSend(Symbol(), OP_BUY, LotsOptimized(), Ask, 3, 0, 0, "", MAGICMA, 0, Blue);`: This line sends a buy order using the `OrderSend()` function with the specified parameters. It assigns the result to the `res` variable.

114. `void CheckForClose()`: This line defines a void function named `CheckForClose` that checks for conditions to close existing orders.

116. `double ma;`: This line declares a double variable `ma` that will store the moving average value.

122. `if (Volume[0] > 1) return;`: This line checks if the current tick volume is greater than 1. If so, it returns, skipping the rest of the function execution. This is to ensure that the function is executed only on the first ticks of a new bar.

125. `ma = iMA(NULL, 0, MovingPeriod, MovingShift, MODE_SMA, PRICE_CLOSE, 0);`: This line calculates the moving average using the `iMA()` function with the specified parameters.

130. `for (int i = 0; i < OrdersTotal(); i++)`: This line starts a loop that iterates over all open orders using the `OrdersTotal()` function.

132. `if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;`: This line selects the order at the current iteration index. If the selection fails, it breaks the loop.

134. `if (OrderMagicNumber() != MAGICMA || OrderSymbol() != Symbol()) continue;`: This line skips the current iteration if the order's magic number does not match the predefined `MAGICMA` value or if the order's symbol does not match the current symbol being traded.

138. `if (OrderType() == OP_BUY)`: This line checks if the order type is a buy order.

140. `if (Open[1] > ma && Close[1] < ma)`: This line checks if the previous bar's open price is greater than the moving average and the previous bar's close price is less than the moving average.

143. `if (!OrderClose(OrderTicket(), OrderLots(), Bid, 3, White))`: This line attempts to close the order using the `OrderClose()` function with the specified parameters. If the function call fails, it prints an error message.

149. `if (OrderType() == OP_SELL)`: This line checks if the order type is a sell order.

151. `if (Open[1] < ma && Close[1] > ma)`: This line checks if the previous bar's open price is less than the moving average and the previous bar's close price is greater than the moving average.

154. `if (!OrderClose(OrderTicket(), OrderLots(), Ask, 3, White))`: This line attempts to close the order using the `OrderClose()` function with the specified parameters. If the function call fails, it prints an error message.

160. `void OnTick()`: This line defines the `OnTick` function, which is called on every tick of the price.

165. `if (Bars < 100 || IsTradeAllowed() == false) return;`: This line checks if the number of bars is less than 100 or if trading is not allowed. If either condition is true, it returns, skipping the rest of the function execution.

169. `if (CalculateCurrentOrders(Symbol()) == 0) CheckForOpen();`: This line checks if there are no open orders for the current symbol. If so, it

 calls the `CheckForOpen` function to check for conditions to open new orders.

171. `CheckForClose();`: This line calls the `CheckForClose` function to check for conditions to close existing orders.

176. `void OnTimer()`: This line defines the `OnTimer` function, which is called on every timer event.

181. `if (CalculateCurrentOrders(Symbol()) == 0) CheckForOpen();`: This line checks if there are no open orders for the current symbol. If so, it calls the `CheckForOpen` function to check for conditions to open new orders.

183. `CheckForClose();`: This line calls the `CheckForClose` function to check for conditions to close existing orders.

That's a walkthrough of the code! Let me know if you have any more questions.
