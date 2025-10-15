/// @title Module for hanlding withdraw base asset request from user
/// @author Scallop Labs
/// @notice User use sCoin to redeem the underlying asset
module protocol::redeem {
  
  use std::type_name::{Self, TypeName};
  use sui::coin::{Self, Coin};
  use sui::tx_context::{Self ,TxContext};
  use sui::clock::{Self, Clock};
  use sui::transfer;
  use sui::event::emit;
  use sui::balance;
  use protocol::market::{Self, Market};
  use protocol::version::{Self, Version};
  use protocol::reserve::MarketCoin;
  use protocol::error;
  use whitelist::whitelist;

  struct RedeemEvent has copy, drop {
    redeemer: address,
    withdraw_asset: TypeName,
    withdraw_amount: u64,
    burn_asset: TypeName,
    burn_amount: u64,
    time: u64,
  }

  /// @notice Redeem the underlying assets with sCoin, and transfer to the sender
  /// @dev This is a wrapper of `redeem`, meant to called by frontend
  /// @param version The version control object, contract version must match with this
  /// @param market The Scallop market object, it contains base assets, and related protocol configs
  /// @param coin The sCoin to exchange for underlying base asset
  /// @param clock The SUI system Clock object
  /// @ctx The SUI transaction context object
  /// @custom:T The type of base asset to redeem
  public entry fun redeem_entry<T>(
    version: &Version,
    market: &mut Market,
    coin: Coin<MarketCoin<T>>,
    clock: &Clock,
    ctx: &mut TxContext,
  ) {
    let coin = redeem(version, market, coin, clock, ctx);
    transfer::public_transfer(coin, tx_context::sender(ctx));
  }

  /// @notice Redeem the underlying assets with sCoin
  /// @dev sCoin is a standard coin, its exchange rate becomes higher as time goes by due to generated interest
  /// @param version The version control object, contract version must match with this
  /// @param market The Scallop market object, it contains base assets, and related protocol configs
  /// @param coin The sCoin to exchange for underlying base asset
  /// @param clock The SUI system Clock object
  /// @ctx The SUI transaction context object
  /// @custom:T The type of base asset to redeem
  /// @return The redeemed underlying asset
  public fun redeem<T>(
    version: &Version,
    market: &mut Market,
    coin: Coin<MarketCoin<T>>,
    clock: &Clock,
    ctx: &mut TxContext,
  ): Coin<T> {
    // check version
    version::assert_current_version(version);

    // check if sender is in whitelist
    market::assert_whitelist_access(market, ctx);

    // Redeem the underlying asset and burn sCoin
    // The exchange rate has reflected the interest generated
    let now = clock::timestamp_ms(clock) / 1000;
    let market_coin_amount = coin::value(&coin);
    let redeem_balance = market::handle_redeem(market, coin::into_balance(coin), now);

    // emit Redeem Event
    emit(RedeemEvent {
      redeemer: tx_context::sender(ctx),
      withdraw_asset: type_name::get<T>(),
      withdraw_amount: balance::value(&redeem_balance),
      burn_asset: type_name::get<MarketCoin<T>>(),
      burn_amount: market_coin_amount,
      time: now
    });

    // return the redeemed asset
    coin::from_balance(redeem_balance, ctx)
  }
}
