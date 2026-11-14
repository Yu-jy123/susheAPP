import { describe, expect, it } from '@ohos/hypium';
import { AutomationState, Condition, Device, Rule, defaultState } from '../main/ets/model/Automation';
import { decodeState } from '../main/ets/model/StateCodec';
import { evaluate, matches, validEnvironment, validRule } from '../main/ets/model/RuleEngine';

export default function ruleEngineTest() {
  describe('DormAutomationRuleEngine', () => {
    it('normal_hot_and_dry_changes_two_devices', 0, () => {
      let state: AutomationState = defaultState();
      state.environment = { temperature: 32, humidity: 30, light: 800 };
      let result = evaluate(state, 'T1');
      expect(result.devices.find((device: Device) => device.id === 'ac')?.on).assertTrue();
      expect(result.devices.find((device: Device) => device.id === 'humidifier')?.on).assertTrue();
      expect(result.logs.length > 1).assertTrue();
    });

    it('normal_two_conditions_must_both_match', 0, () => {
      let state: AutomationState = defaultState();
      state.environment = { temperature: 26, humidity: 65, light: 100 };
      expect(evaluate(state, 'T2').devices.find((device: Device) => device.id === 'light')?.on).assertTrue();
      state.environment.humidity = 85;
      expect(evaluate(state, 'T3').devices.find((device: Device) => device.id === 'light')?.on).assertFalse();
    });

    it('boundary_equality_is_inclusive_only_for_greater_equal', 0, () => {
      let state: AutomationState = defaultState();
      state.environment.temperature = 28;
      expect(evaluate(state, 'T4').devices.find((device: Device) => device.id === 'ac')?.on).assertTrue();
      let strict: Condition = { field: 'temperature', operator: '>', threshold: 28 };
      expect(matches(strict, state.environment)).assertFalse();
    });

    it('conflict_higher_priority_wins_and_logs_skipped_action', 0, () => {
      let state: AutomationState = defaultState();
      state.environment.light = 50;
      state.rules.push({ id: 'R6', name: '关灯', enabled: true, priority: 10,
        first: { field: 'light', operator: '<', threshold: 200 }, second: null,
        deviceId: 'light', turnOn: false });
      let result = evaluate(state, 'T5');
      expect(result.devices.find((device: Device) => device.id === 'light')?.on).assertFalse();
      expect(result.logs.some((log) => log.message.includes('冲突'))).assertTrue();
    });

    it('conflict_equal_priority_uses_rule_id', 0, () => {
      let state: AutomationState = defaultState();
      state.rules = [
        { id: 'B', name: '关灯', enabled: true, priority: 5,
          first: { field: 'light', operator: '>=', threshold: 0 }, second: null,
          deviceId: 'light', turnOn: false },
        { id: 'A', name: '开灯', enabled: true, priority: 5,
          first: { field: 'light', operator: '>=', threshold: 0 }, second: null,
          deviceId: 'light', turnOn: true }
      ];
      expect(evaluate(state, 'T6').devices.find((device: Device) => device.id === 'light')?.on).assertTrue();
    });

    it('boundary_environment_limits_are_valid', 0, () => {
      expect(validEnvironment({ temperature: -20, humidity: 0, light: 0 })).assertTrue();
      expect(validEnvironment({ temperature: 50, humidity: 100, light: 2000 })).assertTrue();
    });

    it('exception_out_of_range_environment_is_rejected', 0, () => {
      let state: AutomationState = defaultState();
      state.environment.humidity = 101;
      expect(validEnvironment(state.environment)).assertFalse();
      let rejected: boolean = false;
      try { evaluate(state, 'T7'); } catch (error) { rejected = true; }
      expect(rejected).assertTrue();
    });

    it('exception_invalid_rule_is_rejected', 0, () => {
      let state: AutomationState = defaultState();
      let rule: Rule = state.rules[0];
      rule.first.threshold = 999;
      expect(validRule(rule, state.devices)).assertFalse();
    });

    it('recovery_valid_state_round_trip_and_corruption_fails', 0, () => {
      let state: AutomationState = defaultState();
      state.devices[0].on = true;
      let restored: AutomationState = decodeState(JSON.stringify(state));
      expect(restored.devices[0].on).assertTrue();
      let rejected: boolean = false;
      try { decodeState('{bad-json'); } catch (error) { rejected = true; }
      expect(rejected).assertTrue();
    });
  });
}
