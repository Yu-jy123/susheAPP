import { AutomationState, Condition, Device, Environment, ExecutionLog, Rule, Scenario, defaultState } from '../model/Automation';
import { evaluate, validRule } from '../model/RuleEngine';
import { StateStore } from '../data/StateStore';

const FIELDS: string[] = ['temperature', 'humidity', 'light'];
const FIELD_NAMES: string[] = ['温度 °C', '湿度 %', '光照 lx'];
const OPERATORS: string[] = ['<', '<=', '>', '>=', '=='];
const DEVICE_IDS: string[] = ['light', 'ac', 'curtain', 'humidifier'];
const DEVICE_NAMES: string[] = ['照明', '空调', '窗帘', '加湿器'];

@Entry
@Component
struct Index {
  @State private state: AutomationState = defaultState();
  @State private temperature: number = 26;
  @State private humidity: number = 45;
  @State private light: number = 500;
  @State private tab: number = 0;
  @State private notice: string = '准备就绪';
  @State private editorId: string = '';
  @State private ruleName: string = '';
  @State private fieldIndex: number = 0;
  @State private operatorIndex: number = 3;
  @State private threshold: string = '28';
  @State private hasSecond: boolean = false;
  @State private secondFieldIndex: number = 1;
  @State private secondOperatorIndex: number = 0;
  @State private secondThreshold: string = '40';
  @State private deviceIndex: number = 0;
  @State private turnOn: boolean = true;
  @State private priority: number = 5;
  @State private scenarioName: string = '';
  private store: StateStore | null = null;

  aboutToAppear(): void {
    try {
      this.store = new StateStore(getContext(this));
      this.state = this.store.load();
      this.notice = '已恢复本地保存的规则、设备、场景与日志';
    } catch (error) {
      this.state = defaultState();
      this.notice = '存档读取失败，已载入默认数据：' + String(error);
      if (this.store !== null) {
        this.store.save(this.state).catch((saveError: Error) => {
          this.notice = '默认数据保存失败：' + String(saveError);
        });
      }
    }
    this.temperature = this.state.environment.temperature;
    this.humidity = this.state.environment.humidity;
    this.light = this.state.environment.light;
  }

  private refresh(): void {
    this.state = JSON.parse(JSON.stringify(this.state)) as AutomationState;
    this.temperature = this.state.environment.temperature;
    this.humidity = this.state.environment.humidity;
    this.light = this.state.environment.light;
    if (this.store !== null) {
      this.store.save(this.state).catch((error: Error) => {
        this.notice = '保存失败：' + String(error);
      });
    }
  }

  private simulate(): void {
    try {
      let runId: number = this.state.nextId++;
      let result = evaluate(this.state, new Date().toLocaleString());
      result.logs.forEach((log: ExecutionLog) => log.id += '-' + runId);
      this.state.devices = result.devices;
      this.state.logs = result.logs.concat(this.state.logs).slice(0, 100);
      this.notice = '已计算 ' + result.logs.length + ' 条执行记录';
      this.refresh();
    } catch (error) {
      this.notice = '模拟未执行：' + String(error);
    }
  }

  private changeEnvironment(field: string, delta: number): void {
    let env: Environment = this.state.environment;
    let limited: boolean = false;
    if (field === 'temperature') {
      let next: number = env.temperature + delta;
      limited = next < -20 || next > 50;
      env.temperature = Math.max(-20, Math.min(50, next));
    }
    if (field === 'humidity') {
      let next: number = env.humidity + delta;
      limited = next < 0 || next > 100;
      env.humidity = Math.max(0, Math.min(100, next));
    }
    if (field === 'light') {
      let next: number = env.light + delta;
      limited = next < 0 || next > 2000;
      env.light = Math.max(0, Math.min(2000, next));
    }
    this.simulate();
    if (limited) { this.notice = '已达到环境数据允许的边界值'; }
  }

  private loadScenario(scenario: Scenario): void {
    this.state.environment = {
      temperature: scenario.environment.temperature,
      humidity: scenario.environment.humidity,
      light: scenario.environment.light
    };
    this.simulate();
    this.notice = '已演练场景：' + scenario.name;
  }

  private addScenario(): void {
    let name: string = this.scenarioName.trim();
    if (name.length === 0) { this.notice = '请先输入场景名称'; return; }
    let id: string = 'S' + this.state.nextId++;
    this.state.scenarios.push({ id: id, name: name, environment: {
      temperature: this.state.environment.temperature,
      humidity: this.state.environment.humidity,
      light: this.state.environment.light
    }});
    this.scenarioName = '';
    this.notice = '已保存场景：' + name;
    this.refresh();
  }

  private toggleDevice(id: string): void {
    let device: Device | undefined = this.state.devices.find((item: Device) => item.id === id);
    if (device === undefined) { return; }
    device.on = !device.on;
    this.state.logs.unshift({ id: String(Date.now()), time: new Date().toLocaleString(),
      ruleId: '手动', message: device.name + (device.on ? '开启' : '关闭') });
    this.notice = '已手动设置' + device.name;
    this.refresh();
  }

  private clearEditor(): void {
    this.editorId = '';
    this.ruleName = '';
    this.fieldIndex = 0;
    this.operatorIndex = 3;
    this.threshold = '28';
    this.hasSecond = false;
    this.secondFieldIndex = 1;
    this.secondOperatorIndex = 0;
    this.secondThreshold = '40';
    this.deviceIndex = 0;
    this.turnOn = true;
    this.priority = 5;
  }

  private editRule(rule: Rule): void {
    this.editorId = rule.id;
    this.ruleName = rule.name;
    this.fieldIndex = Math.max(0, FIELDS.indexOf(rule.first.field));
    this.operatorIndex = Math.max(0, OPERATORS.indexOf(rule.first.operator));
    this.threshold = String(rule.first.threshold);
    this.hasSecond = rule.second !== null;
    if (rule.second !== null) {
      this.secondFieldIndex = Math.max(0, FIELDS.indexOf(rule.second.field));
      this.secondOperatorIndex = Math.max(0, OPERATORS.indexOf(rule.second.operator));
      this.secondThreshold = String(rule.second.threshold);
    }
    this.deviceIndex = Math.max(0, DEVICE_IDS.indexOf(rule.deviceId));
    this.turnOn = rule.turnOn;
    this.priority = rule.priority;
    this.tab = 2;
  }

  private saveRule(): void {
    let first: Condition = { field: FIELDS[this.fieldIndex], operator: OPERATORS[this.operatorIndex],
      threshold: Number(this.threshold) };
    let second: Condition | null = this.hasSecond ? {
      field: FIELDS[this.secondFieldIndex], operator: OPERATORS[this.secondOperatorIndex],
      threshold: Number(this.secondThreshold)
    } : null;
    let id: string = this.editorId || 'R' + this.state.nextId;
    let old: Rule | undefined = this.state.rules.find((item: Rule) => item.id === id);
    let rule: Rule = { id: id, name: this.ruleName.trim(), enabled: old ? old.enabled : true,
      priority: this.priority, first: first, second: second,
      deviceId: DEVICE_IDS[this.deviceIndex], turnOn: this.turnOn };
    if (this.threshold.trim() === '' || (this.hasSecond && this.secondThreshold.trim() === '') ||
      !validRule(rule, this.state.devices)) {
      this.notice = '规则无效：检查名称、阈值范围和优先级';
      return;
    }
    if (old) {
      let position: number = this.state.rules.findIndex((item: Rule) => item.id === id);
      this.state.rules[position] = rule;
    } else {
      this.state.nextId++;
      this.state.rules.push(rule);
    }
    this.notice = '已保存规则：' + rule.name;
    this.clearEditor();
    this.refresh();
  }

  private toggleRule(id: string): void {
    let rule: Rule | undefined = this.state.rules.find((item: Rule) => item.id === id);
    if (rule !== undefined) {
      rule.enabled = !rule.enabled;
      this.notice = rule.name + (rule.enabled ? '已启用' : '已停用');
      this.refresh();
    }
  }

  private deleteRule(id: string): void {
    this.state.rules = this.state.rules.filter((rule: Rule) => rule.id !== id);
    if (this.editorId === id) { this.clearEditor(); }
    this.notice = '已删除规则 ' + id;
    this.refresh();
  }

  @Builder
  private metric(label: string, field: string, step: number): void {
    Row() {
      Column() {
        Text(label).fontSize(13).fontColor('#60718A');
        Text(field === 'temperature' ? String(this.temperature) :
          field === 'humidity' ? String(this.humidity) : String(this.light))
          .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#15243A');
      }.alignItems(HorizontalAlign.Start).layoutWeight(1);
      Button('−').onClick(() => this.changeEnvironment(field, -step));
      Button('+').onClick(() => this.changeEnvironment(field, step)).margin({ left: 8 });
    }.width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(14).margin({ bottom: 8 });
  }

  @Builder
  private navigation(): void {
    Row() {
      Button('总览').onClick(() => this.tab = 0).backgroundColor(this.tab === 0 ? '#2365D1' : '#E8EEF8')
        .fontColor(this.tab === 0 ? '#FFFFFF' : '#32445E');
      Button('环境').onClick(() => this.tab = 1).backgroundColor(this.tab === 1 ? '#2365D1' : '#E8EEF8')
        .fontColor(this.tab === 1 ? '#FFFFFF' : '#32445E');
      Button('规则').onClick(() => this.tab = 2).backgroundColor(this.tab === 2 ? '#2365D1' : '#E8EEF8')
        .fontColor(this.tab === 2 ? '#FFFFFF' : '#32445E');
      Button('日志').onClick(() => this.tab = 3).backgroundColor(this.tab === 3 ? '#2365D1' : '#E8EEF8')
        .fontColor(this.tab === 3 ? '#FFFFFF' : '#32445E');
    }.justifyContent(FlexAlign.SpaceBetween).width('100%').margin({ top: 16, bottom: 14 });
  }

  @Builder
  private overview(): void {
    Column({ space: 10 }) {
      Text('设备状态').fontSize(20).fontWeight(FontWeight.Bold).width('100%');
      ForEach(this.state.devices, (device: Device) => {
        Row() {
          Column() {
            Text(device.name).fontSize(17).fontWeight(FontWeight.Medium);
            Text(device.on ? '运行中' : '已关闭').fontColor(device.on ? '#16805E' : '#758397').fontSize(12);
          }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Button(device.on ? '关闭' : '开启').onClick(() => this.toggleDevice(device.id));
        }.width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(14);
      }, (device: Device) => device.id + '-' + String(device.on));
      Text('最近执行').fontSize(20).fontWeight(FontWeight.Bold).width('100%').margin({ top: 10 });
      Text(this.state.logs.length ? this.state.logs[0].message : '调整环境或加载场景后，这里会显示执行结果。')
        .fontSize(14).fontColor('#42536B').width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(14);
      Button('立即运行规则').width('100%').onClick(() => this.simulate());
    }.width('100%');
  }

  @Builder
  private environmentPanel(): void {
    Column() {
      Text('模拟环境').fontSize(20).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 12 });
      this.metric('温度 °C', 'temperature', 1);
      this.metric('湿度 %', 'humidity', 5);
      this.metric('光照 lx', 'light', 50);
      Text('场景演练').fontSize(20).fontWeight(FontWeight.Bold).width('100%').margin({ top: 16, bottom: 10 });
      ForEach(this.state.scenarios, (scenario: Scenario) => {
        Row() {
          Column() {
            Text(scenario.name).fontSize(16).fontWeight(FontWeight.Medium);
            Text(`${scenario.environment.temperature}°C · ${scenario.environment.humidity}% · ${scenario.environment.light} lx`)
              .fontSize(12).fontColor('#60718A');
          }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          Button('加载').onClick(() => this.loadScenario(scenario));
        }.width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(14).margin({ bottom: 8 });
      }, (scenario: Scenario) => scenario.id);
      Row() {
        TextInput({ placeholder: '新场景名称', text: this.scenarioName })
          .onChange((value: string) => this.scenarioName = value).layoutWeight(1);
        Button('保存当前环境').onClick(() => this.addScenario()).margin({ left: 8 });
      }.width('100%').margin({ top: 6 });
    }.width('100%');
  }

  @Builder
  private rulesPanel(): void {
    Column() {
      Row() {
        Text('自动化规则').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1);
        Button('新建').onClick(() => this.clearEditor());
      }.width('100%').margin({ bottom: 12 });
      ForEach(this.state.rules, (rule: Rule) => {
        Column() {
          Row() {
            Text(rule.name).fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1);
            Text('P' + rule.priority).fontColor('#2365D1');
          }.width('100%');
          Text(rule.first.field + ' ' + rule.first.operator + ' ' + rule.first.threshold +
            (rule.second ? ' 且 ' + rule.second.field + ' ' + rule.second.operator + ' ' + rule.second.threshold : '') +
            ' → ' + rule.deviceId + (rule.turnOn ? ' 开启' : ' 关闭'))
            .fontSize(12).fontColor('#60718A').width('100%').margin({ top: 5, bottom: 8 });
          Row({ space: 8 }) {
            Button(rule.enabled ? '停用' : '启用').onClick(() => this.toggleRule(rule.id));
            Button('编辑').onClick(() => this.editRule(rule));
            Button('删除').onClick(() => this.deleteRule(rule.id));
          }.width('100%');
        }.alignItems(HorizontalAlign.Start).width('100%').padding(14)
          .backgroundColor('#FFFFFF').borderRadius(14).margin({ bottom: 8 });
      }, (rule: Rule) => JSON.stringify(rule));
      Text(this.editorId ? '编辑规则 ' + this.editorId : '新建规则')
        .fontSize(18).fontWeight(FontWeight.Bold).width('100%').margin({ top: 16, bottom: 10 });
      TextInput({ placeholder: '规则名称', text: this.ruleName })
        .onChange((value: string) => this.ruleName = value).margin({ bottom: 8 });
      Row({ space: 8 }) {
        Button(FIELD_NAMES[this.fieldIndex]).onClick(() => this.fieldIndex = (this.fieldIndex + 1) % FIELDS.length);
        Button(OPERATORS[this.operatorIndex]).onClick(() => this.operatorIndex = (this.operatorIndex + 1) % OPERATORS.length);
        TextInput({ placeholder: '阈值', text: this.threshold }).type(InputType.Number)
          .onChange((value: string) => this.threshold = value).layoutWeight(1);
      }.width('100%').margin({ bottom: 8 });
      Button(this.hasSecond ? '移除第二条件' : '添加第二条件（且）')
        .onClick(() => this.hasSecond = !this.hasSecond).margin({ bottom: 8 });
      if (this.hasSecond) {
        Row({ space: 8 }) {
          Button(FIELD_NAMES[this.secondFieldIndex]).onClick(() => this.secondFieldIndex = (this.secondFieldIndex + 1) % FIELDS.length);
          Button(OPERATORS[this.secondOperatorIndex]).onClick(() => this.secondOperatorIndex = (this.secondOperatorIndex + 1) % OPERATORS.length);
          TextInput({ placeholder: '阈值', text: this.secondThreshold }).type(InputType.Number)
            .onChange((value: string) => this.secondThreshold = value).layoutWeight(1);
        }.width('100%').margin({ bottom: 8 });
      }
      Row({ space: 8 }) {
        Button(DEVICE_NAMES[this.deviceIndex]).onClick(() => this.deviceIndex = (this.deviceIndex + 1) % DEVICE_IDS.length);
        Button(this.turnOn ? '开启' : '关闭').onClick(() => this.turnOn = !this.turnOn);
        Button('优先级 ' + this.priority).onClick(() => this.priority = (this.priority + 1) % 11);
      }.width('100%').margin({ bottom: 8 });
      Button('保存规则').width('100%').onClick(() => this.saveRule());
      Text('点击字段和比较符可切换选项；优先级越高越先执行，同一设备每轮只执行第一条命中的规则。')
        .fontSize(12).fontColor('#60718A').width('100%').margin({ top: 8 });
    }.width('100%');
  }

  @Builder
  private logsPanel(): void {
    Column() {
      Row() {
        Text('执行日志').fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1);
        Button('清空').onClick(() => { this.state.logs = []; this.refresh(); });
      }.width('100%').margin({ bottom: 12 });
      ForEach(this.state.logs, (log: ExecutionLog) => {
        Column() {
          Text(log.time + ' · ' + log.ruleId).fontSize(12).fontColor('#60718A').width('100%');
          Text(log.message).fontSize(14).fontColor('#15243A').width('100%').margin({ top: 5 });
        }.alignItems(HorizontalAlign.Start).width('100%').padding(14)
          .backgroundColor('#FFFFFF').borderRadius(14).margin({ bottom: 8 });
      }, (log: ExecutionLog) => log.id);
      if (this.state.logs.length === 0) {
        Text('暂无日志。到“环境”加载场景或调整数据即可运行规则。').fontColor('#60718A');
      }
    }.width('100%');
  }

  build(): void {
    Column() {
      Column() {
        Text('宿舍联控台').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#15243A').width('100%');
        Text('本地环境模拟 · 规则编排 · 可追溯日志').fontSize(13).fontColor('#60718A').width('100%');
        this.navigation();
        Text(this.notice).fontSize(12).fontColor('#2365D1').width('100%').margin({ bottom: 12 });
      }.width('100%').padding({ left: 18, right: 18, top: 18 });
      Scroll() {
        Column() {
          if (this.tab === 0) { this.overview(); }
          if (this.tab === 1) { this.environmentPanel(); }
          if (this.tab === 2) { this.rulesPanel(); }
          if (this.tab === 3) { this.logsPanel(); }
        }.padding({ left: 18, right: 18, bottom: 24 }).width('100%');
      }.layoutWeight(1).width('100%');
    }.width('100%').height('100%').backgroundColor('#F2F5FA');
  }
}

