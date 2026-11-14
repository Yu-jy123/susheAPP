import { AutomationState, Condition, Device, Environment, ExecutionLog, Rule } from './Automation';

export interface EvaluationResult {
  devices: Device[];
  logs: ExecutionLog[];
}

export function validEnvironment(env: Environment): boolean {
  return Number.isFinite(env.temperature) && env.temperature >= -20 && env.temperature <= 50 &&
    Number.isFinite(env.humidity) && env.humidity >= 0 && env.humidity <= 100 &&
    Number.isFinite(env.light) && env.light >= 0 && env.light <= 2000;
}

export function validRule(rule: Rule, devices: Device[]): boolean {
  if (!rule.id || !rule.name.trim() || !Number.isInteger(rule.priority) || rule.priority < 0 || rule.priority > 10) {
    return false;
  }
  if (!validCondition(rule.first) || (rule.second !== null && !validCondition(rule.second))) {
    return false;
  }
  return devices.some((device: Device) => device.id === rule.deviceId);
}

function validCondition(condition: Condition): boolean {
  if (condition.field !== 'temperature' && condition.field !== 'humidity' && condition.field !== 'light') {
    return false;
  }
  if (condition.operator !== '<' && condition.operator !== '<=' && condition.operator !== '>' &&
    condition.operator !== '>=' && condition.operator !== '==') {
    return false;
  }
  if (!Number.isFinite(condition.threshold)) {
    return false;
  }
  let sample: Environment = { temperature: 0, humidity: 0, light: 0 };
  if (condition.field === 'temperature') { sample.temperature = condition.threshold; }
  if (condition.field === 'humidity') { sample.humidity = condition.threshold; }
  if (condition.field === 'light') { sample.light = condition.threshold; }
  return validEnvironment(sample);
}

function reading(env: Environment, field: string): number {
  if (field === 'temperature') { return env.temperature; }
  if (field === 'humidity') { return env.humidity; }
  return env.light;
}

export function matches(condition: Condition, env: Environment): boolean {
  let value: number = reading(env, condition.field);
  if (condition.operator === '<') { return value < condition.threshold; }
  if (condition.operator === '<=') { return value <= condition.threshold; }
  if (condition.operator === '>') { return value > condition.threshold; }
  if (condition.operator === '>=') { return value >= condition.threshold; }
  return value === condition.threshold;
}

export function evaluate(state: AutomationState, timestamp: string): EvaluationResult {
  if (!validEnvironment(state.environment)) { throw new Error('环境数据超出允许范围'); }
  let devices: Device[] = state.devices.map((device: Device): Device => {
    let copy: Device = { id: device.id, name: device.name, on: device.on };
    return copy;
  });
  let logs: ExecutionLog[] = [];
  let candidates: Rule[] = state.rules.filter((rule: Rule) => {
    if (!rule.enabled) { return false; }
    if (!validRule(rule, devices)) { throw new Error('规则数据无效：' + rule.id); }
    return matches(rule.first, state.environment) && (rule.second === null || matches(rule.second, state.environment));
  });
  candidates.sort((a: Rule, b: Rule) => b.priority - a.priority || a.id.localeCompare(b.id));
  let claimed: string[] = [];
  candidates.forEach((rule: Rule, index: number) => {
    let conditionText: string = rule.first.field + rule.first.operator + rule.first.threshold;
    if (rule.second !== null) {
      conditionText += ' 且 ' + rule.second.field + rule.second.operator + rule.second.threshold;
    }
    if (claimed.includes(rule.deviceId)) {
      logs.push({ id: timestamp + '-' + index, time: timestamp, ruleId: rule.id,
        message: '第' + (index + 1) + '顺位命中 ' + conditionText + '；设备动作冲突，按优先级跳过' });
      return;
    }
    claimed.push(rule.deviceId);
    let device: Device | undefined = devices.find((item: Device) => item.id === rule.deviceId);
    if (device !== undefined) {
      let changed: boolean = device.on !== rule.turnOn;
      device.on = rule.turnOn;
      logs.push({ id: timestamp + '-' + index, time: timestamp, ruleId: rule.id,
        message: '第' + (index + 1) + '顺位命中 ' + conditionText + '；' + device.name +
          (rule.turnOn ? '开启' : '关闭') + (changed ? '，状态已改变' : '，状态未变化') });
    }
  });
  if (logs.length === 0) {
    logs.push({ id: timestamp + '-none', time: timestamp, ruleId: '-', message: '没有规则命中，设备状态保持不变' });
  }
  return { devices: devices, logs: logs };
}
