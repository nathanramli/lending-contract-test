#[test_only]
module protocol::risk_model_t {
  
  use sui::test_scenario::{Self, Scenario};
  use protocol::market::Market;
  use protocol::app::{Self, AdminCap};
  use protocol::constants::{Self, RiskModelParams};
  use protocol::transaction_utils_t;

  public fun add_risk_model_t<T>(
    scenario: &mut Scenario,
    market: &mut Market, admin_cap: &AdminCap, params: &RiskModelParams<T>
  ) {
    test_scenario::next_tx(scenario, @0x0);
    let risk_model = app::create_risk_model_change<T>(
      admin_cap,
      constants::collateral_factor(params),
      constants::liquidation_factor(params),
      constants::liquidation_penalty(params),
      constants::liquidation_discount(params),
      constants::risk_model_scale(params),
      constants::max_collateral_amount(params),
      test_scenario::ctx(scenario)
    );
    app::add_risk_model<T>(
      market,
      admin_cap,
      risk_model,
      test_scenario::ctx(scenario),
    );
    
    transaction_utils_t::skip_epoch(scenario, 11);
    
  }
}
