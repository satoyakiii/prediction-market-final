import { BigInt } from "@graphprotocol/graph-ts";
import {
  FeesWithdrawn,
  MarketCreated,
  MarketResolved,
  SharesBought
} from "../../generated/PredictionMarket/PredictionMarket";
import { FeeWithdrawal, Market, Resolution, SharePurchase } from "../../generated/schema";

export function handleMarketCreated(event: MarketCreated): void {
  let market = new Market(event.params.marketId.toString());
  market.question = event.params.question;
  market.endTime = event.params.endTime;
  market.resolved = false;
  market.outcome = BigInt.zero();
  market.totalVolume = BigInt.zero();
  market.save();
}

export function handleSharesBought(event: SharesBought): void {
  let id = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let purchase = new SharePurchase(id);
  purchase.market = event.params.marketId.toString();
  purchase.buyer = event.params.buyer;
  purchase.amount = event.params.amount;
  purchase.isYes = event.params.isYes;
  purchase.blockNumber = event.block.number;
  purchase.transactionHash = event.transaction.hash;
  purchase.save();

  let market = Market.load(event.params.marketId.toString());
  if (market != null) {
    market.totalVolume = market.totalVolume.plus(event.params.amount);
    market.save();
  }
}

export function handleMarketResolved(event: MarketResolved): void {
  let market = Market.load(event.params.marketId.toString());
  if (market != null) {
    market.resolved = true;
    market.outcome = event.params.outcome;
    market.save();
  }

  let resolution = new Resolution(event.transaction.hash.toHexString() + "-" + event.logIndex.toString());
  resolution.market = event.params.marketId.toString();
  resolution.outcome = event.params.outcome;
  resolution.blockNumber = event.block.number;
  resolution.save();
}

export function handleFeesWithdrawn(event: FeesWithdrawn): void {
  let withdrawal = new FeeWithdrawal(event.transaction.hash.toHexString() + "-" + event.logIndex.toString());
  withdrawal.to = event.params.to;
  withdrawal.amount = event.params.amount;
  withdrawal.blockNumber = event.block.number;
  withdrawal.save();
}
