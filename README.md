# 宿舍联控台

鸿蒙高级应用开发工程师认证期末大作业，选题为“联动实验室——智能宿舍自动化规则编排 App”。应用在本地模拟宿舍环境与设备，无需真实硬件、云平台或网络服务。

## 功能

- 四类设备：照明、空调、窗帘、加湿器，可手动控制。
- 三项环境输入：温度、湿度、光照，调整后立即运行规则。
- 默认五条规则；支持新增、编辑、启停、删除。规则可有两个同时满足的条件。
- 同一设备被多条规则命中时，按优先级从高到低执行；优先级相同按规则 ID 排序，日志记录被跳过的冲突动作。
- 两组预设场景，可保存当前环境为新场景。
- 使用 Preferences 保存环境、设备、规则、场景及最多 100 条日志，启动时恢复。

## 开发和运行环境

- DevEco Studio 6.1.1，目标 HarmonyOS SDK 6.1.1(24)，最低兼容 HarmonyOS 6.1.0(23)，Stage 模型，ArkTS/ArkUI。
- 在 DevEco Studio 中打开工程根目录，等待依赖同步，选择 `entry`，启动手机模拟器或连接 HarmonyOS 设备并运行。
- **工程所在的完整路径应只含英文字母、数字等 DevEco 支持的字符。** 当前工作目录含中文，DevEco 的 Hvigor 会拒绝该路径；请从 GitHub 克隆到例如 `D:\HarmonyProjects\susheAPP` 后打开。
- 首次运行显示默认规则与场景。进入“环境”加载预设场景或改变数据；在“总览”观察设备；在“日志”查看命中条件和冲突原因。进入“规则”可编辑或新建规则。

## 自动化测试

`entry/src/test/RuleEngine.test.ets` 包含 9 条本地测试，覆盖正常、双条件、阈值边界、冲突优先级、相同优先级排序、越界环境、无效规则和损坏存档。依赖同步后，在 DevEco Studio 中运行 `entry/src/test` 的本地测试；本次运行使用了 DevEco 自带的 Hvigor，构建与测试日志保存在 `evidence` 目录。

2026 年 11 月 14 日，本机 DevEco Studio 6.1.1 的实际测试结果为 **Tests run: 9, Failure: 0, Error: 0, Pass: 9**；原始结果见 `evidence/test-result.txt`。本机已成功执行 `assembleHap`，生成未签名 HAP。应用已安装到 HarmonyOS 6.1.0(23) 模拟器：加载白天场景后，空调和加湿器启动；温度调整后页面立即刷新；结束应用进程并重新启动后，设备状态、环境数值及日志恢复。具体步骤和截图见 `evidence/实际运行记录.md`。


## 实际运行截图和录屏

- [环境调整与场景](evidence/environment-verified.jpeg)
- [规则列表及双条件规则](evidence/rules.jpeg)
- [规则执行日志](evidence/logs.jpeg)
- [重启前设备状态](evidence/recovery-before.jpeg)
- [重启后设备状态](evidence/recovery-after.jpeg)
- [重启后环境数值](evidence/recovery-environment.jpeg)

## 演示录屏
完整演示视频（20.8MB，归档存放于Release，点击链接下载观看）
[宿舍联控台演示录屏(https://github.com/Yu-jy123/susheAPP/releases/download/%E5%AE%BF%E8%88%8D%E8%81%94%E6%8E%A7%E5%8F%B0/2026-11-14.212020.mp4))
> 文件SHA256校验值：55cc2030d855d2f792396d6fb8e49b9836116d442e5f18c03c1b10c806e5acf1



## 完整演示脚本

1. 加载“炎热干燥的白天”，检查空调、加湿器及日志。
2. 加载“凉爽昏暗的夜晚”，检查低温关空调及双条件开灯。
3. 新建优先级 10 的“光照低于 200 时关灯”规则，再加载夜晚场景，检查开灯规则被冲突处理跳过。
4. 编辑该规则的优先级或停用它，重新运行，检查设备结果变化。
5. 保存一个自定义场景，结束应用进程后重新打开，核对规则、设备、场景和日志恢复。

## 项目结构

| 路径 | 职责 |
| --- | --- |
| `软件需求说明书.md` | 开发前的需求、接口、数据和验收计划 |
| `entry/src/main/ets/model/Automation.ets` | 数据模型和预设数据 |
| `entry/src/main/ets/model/RuleEngine.ets` | 规则判断、优先级与冲突处理 |
| `entry/src/main/ets/model/StateCodec.ets` | 存档结构验证 |
| `entry/src/main/ets/data/StateStore.ets` | Preferences 读写与进程恢复 |
| `entry/src/main/ets/pages/Index.ets` | ArkUI 页面与用户操作 |
| `entry/src/test/RuleEngine.test.ets` | 自动化测试 |

## 参考资料

- [华为：ArkUI 状态管理概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-state-management-overview/)
- [华为：通过用户首选项实现数据持久化](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/data-persistence-by-preferences/)
- [华为：本地测试](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-local-test/)

## 提交核对

仓库地址为 `https://github.com/Yu-jy123/susheAPP`，账号名称为 `Yu-jy123`。


