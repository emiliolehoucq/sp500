# Growth and decline in the S&P 500 between 2013 and 2015

## Data

I used data from [Kaggle](https://www.kaggle.com/datasets/camnugent/sandp500?resource=download&select=individual_stocks_5yr) and [this](https://github.com/datasets/s-and-p-500-companies) GitHub repository. 

The data goes between 2013 and 2018, so my conclusions are limited to that range. While I think most will be more general, I have yet to explore that.

## Main findings

Most of the companies in the S&P 500 are in industrials and financials, followed by IT, healthcare, and consumer discretionary. The minority of companies are in energy, communications, and materials. Consumer discretionary, consumer staples, utiltiies, and real estate are in between. The [companies by sector](https://github.com/emiliolehoucq/sp500/blob/b1a9f4409018a2312fe8172c7a5932d9ae02bf82/R/companies_by_sector.pdf) graph visualizes this.

As the [sector prices graph](https://github.com/emiliolehoucq/sp500/blob/b1a9f4409018a2312fe8172c7a5932d9ae02bf82/R/sector_prices_over_time.pdf) shows, there is wide variation across sectors. Communications, healthcare, consumer discretionary, and industrials increased the most. Energy remained flat, and utlities almost flat. Consumer staples grew slowly. Financials, IT, materials, and real estate are in between the others.

There is wide variation in growth and decline across sectors. Both the [multiples](https://github.com/emiliolehoucq/sp500/blob/b1a9f4409018a2312fe8172c7a5932d9ae02bf82/R/multiples.pdf) and the [rates of changes](https://github.com/emiliolehoucq/sp500/blob/b1a9f4409018a2312fe8172c7a5932d9ae02bf82/R/rates_of_change.pdf) graphs show the variation. Although the growth of companies is associated with sectors, there is also a good amount of variation within sectors. 

Most companies grew, although at different rates. The growth of most companies is concentrated between 1x and 2.5x, with a monthly rate of change between 0 and 0.75. The companies that declined typically decline at a slower pace, with multiples mostly between 0.5x and 1x and a monthly rate of change between -0.05 and 0.

The companies that grew the most and faster are companies such as Amazon, Nvidia, and Alphabet. Companies such as Chipotle Mexican Grill and IBM declined. You can explore the trajectory of each company in the [individual stocks folder](https://github.com/emiliolehoucq/sp500/tree/main/R/individual_stocks).

## Key takeaways

In general, buying an S&P 500 index fund seems like a good idea, since the S&P 500 tends to go up. Since most stocks go up, even purchasing a random stock is likely to bring gains. (Of coure, this is not an optimal investing strategy.)

Given the variation across sectors and companies, there is room to generate alpha by picking sectors and companies to invest. Of course, there's a question as to whether that's possible over the long term.

## Next steps

I explored growth and decline, but not volatility. That matters, especially in shorter time horizons. I tried a couple of measures, but I am not satisfied with the results. I will next try maximum drawdown and stock beta.

I want to try one way to predict stock prices--and thus pick stocks. I will estimate models to predict a stock price based on the previous day(s) price. I am thinking of using hierarchical linear models since the data has a hierarchical structure (time, stock, sector). I will also try supervised learning models.
