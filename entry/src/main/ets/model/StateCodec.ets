import { AutomationState, Device, Rule, Scenario } from './Automation';
import { validEnvironment, validRule } from './RuleEngine';

export function decodeState(raw: string): AutomationState {
  let parsed: AutomationState = JSON.parse(raw) as AutomationState;
  if (!parsed || !parsed.environment || !validEnvironment(parsed.environment) ||
    !Array.isArray(parsed.devices) || parsed.devices.length !== 4 ||
    !Array.isArray(parsed.rules) || !Array.isArray(parsed.scenarios) || !Array.isArray(parsed.logs) ||
    !Number.isInteger(parsed.nextId) || parsed.nextId < 1) {
    throw new Error('存档结构无效');
  }
  let expected: string[] = ['light', 'ac', 'curtain', 'humidifier'];
  expected.forEach((id: string) => {
    if (!parsed.devices.some((device: Device) => device.id === id && typeof device.on === 'boolean')) {
      throw new Error('设备存档无效');
    }
  });
  let ids: string[] = [];
  parsed.rules.forEach((rule: Rule) => {
    if (!validRule(rule, parsed.devices) || ids.includes(rule.id) || typeof rule.enabled !== 'boolean') {
      throw new Error('规则存档无效');
    }
    ids.push(rule.id);
  });
  parsed.scenarios.forEach((scenario: Scenario) => {
    if (!scenario.id || !scenario.name || !validEnvironment(scenario.environment)) {
      throw new Error('场景存档无效');
    }
  });
  return parsed;
}
