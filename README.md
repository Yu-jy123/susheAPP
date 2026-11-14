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

- DevEco Studio 6.1.1，HarmonyOS SDK 6.1.1(24)，Stage 模型，ArkTS/ArkUI。
- 在 DevEco Studio 中打开工程根目录，等待依赖同步，选择 `entry`，启动手机模拟器或连接 HarmonyOS 设备并运行。
- **工程所在的完整路径应只含英文字母、数字等 DevEco 支持的字符。** 当前工作目录含中文，DevEco 的 Hvigor 会拒绝该路径；请从 GitHub 克隆到例如 `D:\HarmonyProjects\susheAPP` 后打开。
- 首次运行显示默认规则与场景。进入“环境”加载预设场景或改变数据；在“总览”观察设备；在“日志”查看命中条件和冲突原因。进入“规则”可编辑或新建规则。

## 自动化测试

`entry/src/test/RuleEngine.test.ets` 包含 9 条本地测试，覆盖正常、双条件、阈值边界、冲突优先级、相同优先级排序、越界环境、无效规则和损坏存档。使用 DevEco Studio 右键运行 `entry/src/test`，或在工程根目录执行：

```text
hvigorw test -p module=entry -p coverage=false
```

2026 年 11 月 14 日，本机 DevEco Studio 6.1.1 的实际测试结果为 **Tests run: 9, Failure: 0, Error: 0, Pass: 9**；原始结果见 `evidence/test-result.txt`。本机已成功执行 `assembleHap`，生成未签名 HAP。**界面、模拟器操作、进程重启恢复及演示录屏尚需设备实测**，不能以编译或单元测试代替。

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

个人报告、仓库链接和本人 GitHub 账号名称需按课程要求提交；学习通答案处必须同时填写有效仓库链接与账号名称。运行截图、录屏、真实进程恢复记录和报告中的个人经历应取自实际执行，不能由代码推断或虚构。
