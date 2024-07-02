#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

CTrade trade;

double lots=0.1;
int takeProfit=100;
int stopLoss=100;
input int magic=11;

int OnInit(){

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}

void OnTick(){

  //Trade code=
  double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
  
  ask=NormalizeDouble(ask,_Digits);
  bid=NormalizeDouble(bid,_Digits);
  
  //Trade buying=
  double tpB=ask+takeProfit*_Point;
  double slB=ask-takeProfit*_Point;
  
  tpB=NormalizeDouble(tpB,_Digits);
  slB=NormalizeDouble(slB,_Digits);
  
  //Trade selling=
  double tpS=bid-takeProfit*_Point;
  double slS=bid+takeProfit*_Point;
  
  tpS=NormalizeDouble(tpS,_Digits);
  slS=NormalizeDouble(slS,_Digits);
  
  //Closing Price code=
  MqlRates priceArray[];
  ArraySetAsSeries(priceArray,true);
  int Data=CopyRates(_Symbol,PERIOD_M15,0,3,priceArray);
  if(Data<3) return; //review if it get the datas enough
  double closingPrice=priceArray[0].close;
  
  //MA code=
  double maArray[];
  ArraySetAsSeries(maArray,true);
  int maDef=iMA(_Symbol,PERIOD_M15,50,0,MODE_EMA,PRICE_CLOSE);
  int copied=CopyBuffer(maDef,0,0,3,maArray);
  if(copied<3) return;
  double maValue=NormalizeDouble(maArray[0],6);
  
  //FRACTALS code=
  double fracUpArray[];
  double fracDownArray[];
  
  ArraySetAsSeries(fracUpArray,true);
  ArraySetAsSeries(fracDownArray,true);
  
  int fracDef=iFractals(_Symbol,PERIOD_M15);
  
  CopyBuffer(fracDef,UPPER_LINE,2,1,fracUpArray);
  CopyBuffer(fracDef,LOWER_LINE,2,1,fracDownArray);
  
  double fracUpValue=NormalizeDouble(fracUpArray[0],5);
  double fracDownValue=NormalizeDouble(fracDownArray[0],5);
  
  if(fracUpValue==EMPTY_VALUE){
    fracUpValue=0;
  }
  if(fracDownValue==EMPTY_VALUE){
    fracDownValue=0;
  }
  
  //ALLIGATOR code=
  double jawsArray[];
  double teethArray[];
  double lipsArray[];
  
  ArraySetAsSeries(jawsArray,true);
  ArraySetAsSeries(teethArray,true);
  ArraySetAsSeries(lipsArray,true);
  
  int alligatorDef=iAlligator(_Symbol,PERIOD_M15,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN);
  
  CopyBuffer(alligatorDef,0,0,3,jawsArray);
  CopyBuffer(alligatorDef,1,0,3,teethArray);
  CopyBuffer(alligatorDef,2,0,3,lipsArray);
  
  double jawsValue=NormalizeDouble(jawsArray[0],5);
  double teethValue=NormalizeDouble(teethArray[0],5);
  double lipsValue=NormalizeDouble(lipsArray[0],5);
  
  /*
  Strategy One...
  Fractals highs and lows=
  Lower arrow --> Fractals Low
  Upper arrow --> Fractals High
  */
  if(fracUpValue>0){
    Comment("Fractals High around: ", fracUpValue);
  }
  if(fracDownValue>0){
    Comment("Fractals Low around: ",fracDownValue);
  }
  
  //Stop infinite Orders at the same time, code=
  int totalOrders=OrdersTotal();
  bool orderOpenBuy=false;
  bool orderOpenSell=false;
  for(int i=totalOrders-1;i>=0; i--){
    if(OrderSelect(i)){
      if(PositionGetString(POSITION_SYMBOL)==_Symbol){
        if(PositionGetInteger(POSITION_MAGIC)==magic){
          if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
            orderOpenBuy=true;
          }else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
            orderOpenSell=true;
          }
        }
      }
    }
  }
  
  /*
  Strategy Two...
  Fractals with MA=
  The closing price > MA and Lower arrow generated --> buy signal
  The closing price < MA and Higher arrow generated --> sell signal
  */
  if(closingPrice>maValue && fracDownValue!=EMPTY_VALUE && !orderOpenBuy){
    //buying
    Comment("Buy","\n"
            "Current EMA: ",maValue,"\n",
            "Fractals Low around: ",fracDownValue);
    trade.Buy(lots,_Symbol,ask,slB,tpB);
  }
  if(closingPrice<maValue && fracUpValue!=EMPTY_VALUE && !orderOpenSell){
    //selling
    Comment("Sell","\n"
            "Current EMA: ",maValue,"\n",
            "Fractals High around: ",fracUpValue);
    trade.Sell(lots,_Symbol,bid,slS,tpS);
  }
  /*
  Strategy Three...
  Fractals with Alligator=
  The lips > the teet and the jaws, the teeth > the jaws, the closing
  price > the teeth, and the Fractals signal is a lower arrow --> buy signal
  The lips < the teeth and the jaws, the teeth < the jaws, the closing price < 
  the teeth, and the Fractals signal is an upper arrow --> sell signal
  */
  if(lipsValue>teethValue && lipsValue>jawsValue &&
   teethValue>jawsValue && closingPrice>teethValue &&
   fracDownValue != EMPTY_VALUE && !orderOpenBuy){
    //buying
    Comment("Buy","\n",
            "jawsValue= ",jawsValue,"\n",
            "teethValue= ",teethValue,"\n",
            "lipsValue= ",lipsValue,"\n",
            "Fractals Low around: ",fracDownValue);
    trade.Buy(lots,_Symbol,ask,slB,tpB);
   }
   
   if(lipsValue<teethValue && lipsValue<jawsValue && teethValue<jawsValue
   && closingPrice<teethValue && fracUpValue != EMPTY_VALUE && !orderOpenSell){
    //selling
     Comment("Sell","\n",
            "jawsValue= ",jawsValue,"\n",
            "teethValue= ",teethValue,"\n",
            "lipsValue= ",lipsValue,"\n",
            "Fractals High around: ",fracUpValue);
    trade.Sell(lots,_Symbol,bid,slS,tpS);
   }
}