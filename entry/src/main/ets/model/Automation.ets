export interface Environment {
  temperature: number;
  humidity: number;
  light: number;
}

export interface Device {
  id: string;
  name: string;
  on: boolean;
}

export interface Condition {
  field: string;
  operator: string;
  threshold: number;
}

export interface Rule {
  id: string;
  name: string;
  enabled: boolean;
  priority: number;
  first: Condition;
  second: Condition | null;
  deviceId: string;
  turnOn: boolean;
}

export interface Scenario {
  id: string;
  name: string;
  environment: Environment;
}

export interface ExecutionLog {
  id: string;
  time: string;
  ruleId: string;
  message: string;
}

export interface AutomationState {
  environment: Environment;
  devices: Device[];
  rules: Rule[];
  scenarios: Scenario[];
  logs: ExecutionLog[];
  nextId: number;
}

export function defaultState(): AutomationState {
  return {
    environment: { temperature: 26, humidity: 45, light: 500 },
    devices: [
      { id: 'light', name: '照明', on: false },
      { id: 'ac', name: '空调', on: false },
      { id: 'curtain', name: '窗帘', on: false },
      { id: 'humidifier', name: '加湿器', on: false }
    ],
    rules: [
      { id: 'R1', name: '高温开空调', enabled: true, priority: 8,
        first: { field: 'temperature', operator: '>=', threshold: 28 }, second: null, deviceId: 'ac', turnOn: true },
      { id: 'R2', name: '低温关空调', enabled: true, priority: 8,
        first: { field: 'temperature', operator: '<=', threshold: 22 }, second: null, deviceId: 'ac', turnOn: false },
      { id: 'R3', name: '昏暗且湿度未超限时开灯', enabled: true, priority: 9,
        first: { field: 'light', operator: '<', threshold: 300 },
        second: { field: 'humidity', operator: '<', threshold: 80 }, deviceId: 'light', turnOn: true },
      { id: 'R4', name: '干燥开加湿器', enabled: true, priority: 7,
        first: { field: 'humidity', operator: '<', threshold: 40 }, second: null, deviceId: 'humidifier', turnOn: true },
      { id: 'R5', name: '强光关窗帘', enabled: true, priority: 6,
        first: { field: 'light', operator: '>', threshold: 700 }, second: null, deviceId: 'curtain', turnOn: false }
    ],
    scenarios: [
      { id: 'S1', name: '炎热干燥的白天', environment: { temperature: 31, humidity: 30, light: 850 } },
      { id: 'S2', name: '凉爽昏暗的夜晚', environment: { temperature: 20, humidity: 65, light: 80 } }
    ],
    logs: [], nextId: 6
  };
}
