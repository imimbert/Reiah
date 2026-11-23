# haier.apk 逆向分析报告

| 项目 | 内容 |
|---|---|
| 目标文件 | `haier.apk` |
| 文件大小 | 25,914,779 字节（24.71 MB） |
| 文件时间 | 2025-10-09 12:16:36 |
| SHA-256 | `20aa847da8361fde672d0ae74937f94e48e832228ead0ecfe96f0bbabd30a825` |
| 分析工具 | REA（rea-agents 6.8.0）+ JADX headless 通道（`jadx-headless-mcp 0.7.1` / JDK 21.0.7） |
| 分析方法 | `open_binary` / `inspect_artifact` / `binary_session` / `inspect_android_package` / `search_android_classes` / `inspect_android_class` |
| 分析方式 | 纯静态分析，未执行 APK、未联网验证、未抓包 |
| 报告日期 | 2026-10-28（初版为字符串取证，同日经 JADX 通道复核并补充方法级接口） |

> 本轮 JADX 复核所用引擎指纹（由 REA 回传，可复现）：
> `engine=jadx-headless-mcp 0.7.1`、`jar_sha256=6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75`、
> `source_revision=5844800a486d2248fa949b74c9896285f5b54de2`、`bridge_sha256=e5044a8312dd0731f53af3f095508b3e5cff54df6b971c95d4305e2f39b4fa30`。

> **结论摘要**
> `haier.apk` 是 **uni-app（DCloud）打包的混合应用**。JADX 反编译确认：原生 dex 共 **3,579 个类**，
> 其中应用自有类**仅 5 个**（`com.hnyschoolpad.haier.*`），且**不含任何 HTTP 接口定义**，
> 原生层唯一业务动作是把本机用户信息桥接给 JS（`AppPlugin.getUserInfo` → `UserInfo` 单例）。
> 全部业务逻辑与接口位于 `assets/apps/__UNI__104610A/www/app-service.js`（2,761,650 字节）。
> 业务后端为 `https://portal.haierschool.cn/v/`，共提取 **56 个接口**（GET 46 / POST 7 / PUT 1 / DELETE 2），
> 均已定位到 HTTP 方法与关键入参；另接入一个独立 uniCloud 环境。

---

## 1. 应用身份

### 1.1 Android 层（JADX 反编译，AXML 属性区已完整解析）

| 项 | 值 |
|---|---|
| 包名 | `com.hnyschoolpad.haier` |
| Android 版本 | `versionName = "1.21"`，`versionCode = "22"` |
| minSdkVersion | `21`（Android 5.0） |
| targetSdkVersion | `30`（Android 11） |
| compileSdkVersion | `30`（codename `11`） |
| `BUILD_TYPE` | `debug` |
| `DEBUG` 常量 | `false`（DEX 静态值） |
| `debuggable` | `true` |
| `usesCleartextTraffic` | `true`（允许明文 HTTP） |
| `largeHeap` / `allowBackup` / `allowClearUserData` | `true` / `true` / `true` |
| `extractNativeLibs` | `true` |
| 应用显示名 | `海尔学校`（`android:label`） |
| Application 类 | `io.dcloud.application.DCloudApplication` |
| 启动 Activity | `com.hnyschoolpad.haier.HaierPandoraEntry` |
| 深链 scheme | `h56131bcf`（`io.dcloud.PandoraEntryActivity` 的 `VIEW` + `BROWSABLE`） |
| FileProvider authority | `com.hnyschoolpad.haier.dc.fileprovider` |
| `dcloud_appkey` | `99bf68a9865510ae6ba274d0c5313605` |

> `BuildConfig` 五个字段实测值：`APPLICATION_ID=com.hnyschoolpad.haier`、`BUILD_TYPE=debug`、
> `DEBUG=false`、`VERSION_CODE=22`、`VERSION_NAME=1.21`。
> `dcloud_appkey` 已在 AXML 属性区完整解析，**不再是推断值**。

### 1.2 uni-app 层（来自 `www/manifest.json`）

| 项 | 值 |
|---|---|
| 应用名 | `haier-school-pad` |
| uni-app 版本 | `1.0.0`（code `100`）—— 与 Android 层 `1.21(22)` 是**两套独立版本号** |
| uni-app AppID | `__UNI__104610A` |
| 声明平台 | `@platforms: ["android", "iPhone", "iPad"]`（本包为 Android 变体） |
| uni-app 编译器 | `4.15`，`control: uni-v3`，`compilerVersion: 3` |
| 渲染 | `renderer: auto`；`launchwebview: { render: "always", kernel: "WKWebview" }` |
| nvue | `nvueCompiler: uni-app`，`nvueStyleCompiler: uni-app`，`nvueLaunchMode: normal` |
| 启动页 | `__uniappview.html` |
| 状态栏 | `immersed: supportedDevice`，`style: light`，`background: #003678` |
| 统计 | `uniStatistics.enable = false`（未开启 uni 统计） |
| 构建期常量 | `VUE_APP_NAME=haier-school-pad`、`VUE_APP_PLATFORM=app-plus`、`NODE_ENV=production`、`VUE_APP_DARK_MODE=false`、`BASE_URL=/` |
| uni-app 内置权限声明 | `Geolocation`、`UniNView` |
| 容器框架 | DCloud 5+ Runtime |
| 入口 Activity | `com.hnyschoolpad.haier.HaierPandoraEntry`、`io.dcloud.PandoraEntryActivity` |

### 1.3 原生层唯一业务代码（JADX 反编译结论）

dex 共 **3,579 个类**，应用自有包 `com.hnyschoolpad.haier` 下**仅 5 个类**：

| 类 | 成员 | 作用 |
|---|---|---|
| `AppPlugin` | `<init>`、`getUserInfo(UniJSCallback)` | **唯一的业务方法**：把原生用户信息回调给 JS |
| `UserInfo` | 单例 `INSTANCE` + `HashMap<String,String> param`；`getInstance()` / `getUserInfo()` / `setUserInfo(String,String)` / `cleanUserInfo()` | 用户信息内存缓存 |
| `BuildConfig` | 5 个静态字段（见 1.1） | 构建常量 |
| `HaierPandoraEntry` | — | uni-app 启动入口（继承 DCloud 入口） |
| `R` | — | 资源索引 |

**结论：dex 中不存在 Retrofit / OkHttp 接口定义、不存在 URL 常量、不存在加密或签名逻辑。**
原先「字符串池中疑似 AppKey」的推断已由属性区解析取代。

---

## 2. 服务端地址

### 2.1 业务后端（主）

```
BaseURL  : https://portal.haierschool.cn/v/
H5 管理端 : https://portal.haierschool.cn/pad/#/pages/...
```

请求层初始化（`utils/request.js` 反混淆原文）：

```js
o.setConfig(function (e) {
  return e.baseURL = "https://portal.haierschool.cn/v/",
         e.header = {
           "Content-Type": "application/json;charset=utf-8",
           sysType: "3"
         },
         e.timeout = 6e4,
         e;
});
```

请求拦截器：

```js
o.interceptors.request.use(function (e) {
  return new Promise(function (t, n) {
    // c 为「登录是否完成」标记；登录未完成且 URL 不在白名单 u 内 => 请求入队挂起
    c || u.includes(e.url) ? /* 放行 */ : /* push 到队列 l */;
  });
});

// GET 请求参数拼接到 URL
if ("get" === e.method && e.params) {
  var n = e.url + "?" + (0, a.tansParams)(e.params);
  n = n.slice(0, -1);
  e.params = {};
  e.url = n;
}

// 登录完成事件，唤醒挂起队列
uni.$on("loginfinish", function () {
  l.forEach(function (e) { return e(); });
  c = !0;
});
```

默认配置对象：

```js
{ baseURL: "", header: {}, method: "GET", dataType: "json",
  responseType: "text", custom: {}, timeout: 6e4,
  sslVerify: true, firstIpv4: false,
  validateStatus: function (e) { return e >= 200 && e < 300; } }
```

关键特征汇总：

| 特征 | 值 |
|---|---|
| 版本前缀 | `/v/`（所有接口相对该前缀） |
| 自定义请求头 | `sysType: 3`（后端据此区分客户端类型） |
| 认证 | `Authorization: Bearer <token>`，token 取本地存储键 `token` |
| 免鉴权白名单 | `u = ["/refreshToken", "/login"]`（仅这两条不带 token；`/login` 另显式传 `headers: { isToken: false }`） |
| Content-Type | `application/json;charset=utf-8` |
| 超时 | 60000 ms |
| GET 参数 | 经 `tansParams()` 序列化后直接拼接（`n.slice(0,-1)` 去掉末尾多余字符） |
| 登录门控 | `loginfinish` 事件前，非白名单请求排队挂起 |
| 响应处理 | `validateStatus` 仅接受 2xx；字符串响应自动 `JSON.parse` |
| 上传/下载 | 支持 `method: "UPLOAD"` / `"DOWNLOAD"` 分支 |

### 2.2 uniCloud（独立环境）

```js
this.config = Object.assign({}, {
  endpoint: 0 === t.spaceId.indexOf("mp-")
    ? "https://api.next.bspapp.com"
    : "https://api.bspapp.com"
}, t);
this.config.provider   = "aliyun";
this.config.requestUrl = this.config.endpoint + "/client";
this.config.envType    = this.config.envType || "public";
this.config.accessTokenKey = "access_token_" + this.config.spaceId;
```

```
https://api.bspapp.com/client        (spaceId 非 "mp-" 前缀)
https://api.next.bspapp.com/client   (spaceId 以 "mp-" 开头)
```

- 方法：`POST`，`Content-Type: application/json`
- 请求头：`x-serverless-sign`（由 `Oe.sign(payload, this.config.clientSecret)` 生成）、
  `x-basement-token`、`x-client-info`（`encodeURIComponent(JSON.stringify(...))`）、`x-client-token`
- 鉴权类型为 `auth` 时**不携带** `x-basement-token`
- accessToken 存储键：`access_token_<spaceId>`
- 代码中包含 `https://uniapp.dcloud.net.cn/uniCloud/secure-network.html#verify-client`
  （uniCloud「安全网络」客户端校验的官方指引链接）

> `spaceId` 与 `clientSecret` 均为运行时注入，**APK 内未硬编码**。

### 2.3 其他域名（非业务后端）

| 域名 / URL | 来源 | 用途 |
|---|---|---|
| `https://96f0e031-f37a-48ef-84c7-2023f6360c0a.bspapp.com/http/splash-screen/report` | dex | DCloud uni-ad 开屏上报 |
| `https://96f0e031-…bspapp.com/http/rewarded-video/report?p=a&t=` | dex | DCloud uni-ad 激励视频上报 |
| `https://stream.mobihtml5.com/`、`https://stream.dcloud.net.cn/` | dex | DCloud 广告/流媒体资源 |
| `http://m3w.cn/s/` | dex | DCloud 广告短链 |
| `https://ask.dcloud.net.cn/article/{282,283,287,35058,35627,35877,36199}` | dex | DCloud 错误码帮助文档 |
| `https://uniapp.dcloud.net.cn/uniCloud/*` | JS | uni-app 文档 |
| `//tcb-api.tencentcloudapi.com/web` | JS | 腾讯 CloudBase（协议相对 URL） |
| `http://momentjs.com/guides/#/warnings/*` | JS | moment.js 警告文档 |
| `https://github.com/ecomfe/zrender/blob/master/LICENSE.txt` | JS | ECharts/zrender 许可证 |
| `https://github.com/facebook/regenerator/*`、`https://feross.org[/opensource]` | JS | Babel runtime / buffer 许可证 |
| `https://localhost`、`http://localhost` | dex | WebView 本地调试常量 |
| `http://www.w3.org/*`、`http://ns.adobe.com/xap/1.0/`、`http://schemas.android.com/apk/res/android`、`http://www.android.com/` | dex | 标准命名空间常量 |

**未发现任何硬编码 IP 地址。**

---

## 3. 接口清单

> BaseURL 均为 `https://portal.haierschool.cn/v/`。
> 下表由 `app-service.js` 中 **56 个 `uni.request` 调用点**逐一提取（含 HTTP 方法），
> 并经 JADX 复核确认「dex 侧无任何接口定义，接口 100% 来自 JS」。
> 方法分布：**GET 46 / POST 7 / PUT 1 / DELETE 2**。
> 标记 `✅` = 已用真实账号（`H202503018`）实测通过，测试脚本见 `api/` 目录。

### 3.1 认证 / 会话（3）

| 方法 | 路径 | 入参 | 说明 |
|---|---|---|---|
| POST | `/login` ✅ | `{ username, password, sysType: "3" }` | 登录；显式 `headers: { isToken: false }`，不带 token |
| POST | `/refreshToken` | — | 刷新令牌；在白名单内，不带 token |
| GET | `/getInfo` | — | 当前用户信息（角色 / 权限） |

> `/system/user/profile/avatar` 出现在字符串常量中但不经 `request()`（作 `<image>` 头像地址使用）。

### 3.2 一卡通 / 消费 IPass（16）

| 方法 | 路径 | 入参 | 说明 |
|---|---|---|---|
| GET | `/payCardTrade/personCardBalance` | `{ belongUserId }` | 个人卡余额 |
| GET | `/payCardTrade/page` | — | 交易分页 |
| GET | `/payCardTrade/rechargeRecordPage` | — | 充值记录分页 |
| GET | `/payCardTrade/consumeRecordPage` | — | 消费记录分页 |
| POST | `/payCardStatisticsTodo/batchSave` | `data: e`（数组 / 对象） | 统计待办批量保存 |
| GET | `/payCardStatisticsTodo/getRedirectUrl` | — | 统计跳转地址 |
| GET | `/datawayapi/payConsume/overall` | — | 消费总览 |
| GET | `/datawayapi/payConsume/payConsumeText` | — | 消费文案 |
| GET | `/datawayapi/payConsume/consumeTypeAmountStatistics` | — | 消费类型金额统计 |
| GET | `/datawayapi/payConsume/consumeTypeTrend` | — | 消费类型趋势 |
| GET | `/datawayapi/payConsume/personTypeAmountStatistics` | — | 人员类型金额统计 |
| GET | `/datawayapi/payConsume/personalMonthConsumeList` | — | 个人月度消费列表 |
| GET | `/datawayapi/payConsume/personalMonthConsumeResult` | — | 个人月度消费结果 |
| GET | `/datawayapi/payConsume/personalMonthConsumeTrend` | — | 个人月度消费趋势 |
| GET | `/datawayapi/payConsume/studentMonthConsumeSentList` | — | 学生月度消费发送列表 |
| GET | `/datawayapi/foodNotClaim/alarmNotice` | — | 未领取餐食告警 |

另存在一处重复前缀字面量 `/v/datawayapi/payConsume/studentMonthConsumeSentList`
（会拼出 `.../v/v/datawayapi/...`），疑似历史遗留；**该字符串未出现在任何 `request()` 调用点**，需运行时验证是否实际使用。

### 3.3 考勤 / 请假 / 宿舍（6）

| 方法 | 路径 | 入参 |
|---|---|---|
| GET | `/student/signInRecord/allHours` | — |
| GET | `/student/signInRecord/hoursByTime` | — |
| GET | `/student/signInRecord/hoursByCourse` | — |
| GET | `/student/signInRecord/stuClassTable` | `{ beginDate, endDate }` |
| GET | `/student/leaveRecord/list` | — |
| GET | `/student/dorm/selectByStuId/{stuId}` | 路径拼接（`url + .concat(e)`） |

### 3.4 课表 / 班级（3）

| 方法 | 路径 | 入参 |
|---|---|---|
| GET | `/lesson/class/stuMyClasses` ✅ | — |
| GET | `/lesson/class/myClassDetail/{id}` ✅ | 路径拼接 |
| GET | `/lesson/class/myTeachClassStu/{id}` ✅ | 路径拼接 |

### 3.5 订餐 / 食谱（5）

| 方法 | 路径 | 入参 |
|---|---|---|
| GET | `/foodOrderConfig/list` | — |
| GET | `/foodPersonOrders/app/todayFoodOrder` | — |
| GET | `/foodPersonOrders/app/foodOrderWeekList` | — |
| POST | `/foodPersonOrders/app/submitOrChangeFoodOrder` | `data: e` |
| GET | `/foodPersonOrders/getNextFoodWorkday` | — |

### 3.6 学籍档案（2）

| 方法 | 路径 | 入参 |
|---|---|---|
| GET | `/stuArchives/getStudentArchive` | `{ userId }` |
| POST | `/stuArchives/updateStudentArchive` | `data: { userId, ...e }`（`Object.assign({userId}, e)`） |

### 3.7 基础数据（8）

| 方法 | 路径 | 入参 |
|---|---|---|
| GET | `/basedata/year/list` | — |
| GET | `/basedata/year/` | — |
| POST | `/basedata/year` | `data: e` |
| PUT | `/basedata/year` | `data: e` |
| DELETE | `/basedata/year/{yearId}` | 路径拼接（`url + t`） |
| GET | `/database/semester/list` | — |
| POST | `/database/rule` | `data: [e]`（数组包裹） |
| DELETE | `/database/rule/removeByrId/{id}` | 路径拼接 |

### 3.8 通知 / 待办 / 应用中心（13）

| 方法 | 路径 | 入参 | 说明 |
|---|---|---|---|
| GET | `/system/notice/list` | `{ noticeType: "118", pageSize: 3, pageNum: 1 }` | 系统通知列表（**入参为硬编码字面量**） |
| GET | `/system/notice/getRedirectUrl` | `{ noticeId }` | 系统通知跳转 |
| GET | `/manage/notice/page` | — | 通知分页 |
| GET | `/manage/notice/getNoticeInfo/{id}` | 路径拼接 | 通知详情 |
| GET | `/system/news/stuList` | — | 学生新闻列表 |
| GET | `/sysTodoList/getSelfTodoList` | — | 我的待办 |
| GET | `/sysTodoList/getSelfDoneList` | — | 我的已办 |
| GET | `/sysTodoList/getMyPublishedList` | — | 我发布的 |
| GET | `/sysTodoList/getRedirectUrl` | `{ id }` | 待办跳转 |
| GET | `/application/appListFromUser` | — | 用户可用应用 |
| POST | `/application/saveOrUpdateUserCommonlyApp` | `data: e` | 保存常用应用 |
| GET | `/application/getRedirectUrl` | `{ appId }` | 应用跳转 |
| GET | `/sysDynamicTable/v1/getTableValuePage` | `{ dataCode: "bannerList1", bannerType: "student", pageNum, pageSize }` | 动态表格分页（首页 Banner 用） |

### 3.9 请求层原始代码（登录 / 刷新）

```js
// 认证模块（反混淆原文）
t.getInfo = function () {
  return i.default.request({ url: "/getInfo", method: "get" });
};
t.login = function (e, t) {                       // e=username, t=password
  var n = { username: e, password: t, sysType: "3" };
  return i.default.request({ url: "/login", headers: { isToken: !1 }, method: "post", data: n });
};
t.refreshToken = function () {
  return i.default.request({ url: "/refreshToken", method: "post" });
};
```

### 3.10 非业务后端的接口（不属于上表）

| 路径 | 归属 | 说明 |
|---|---|---|
| `/client` | uniCloud | 客户端入口，`POST` + `x-serverless-sign` |
| `/functions/invokeFunction` | uniCloud | 云函数调用（阿里云 `api-hz.cloudbasefunction.cn` 风格） |

### 3.11 统计口径

| 口径 | 数量 |
|---|---|
| `request()` 调用点 | **56** |
| 去重后 (方法, 路径) | **56**（无重复） |
| 其中 GET | 46 |
| 其中 POST | 7 |
| 其中 PUT | 1 |
| 其中 DELETE | 2 |
| JS 中路径类字符串字面量（去重） | 89 |
| 其中：页面路由 `/pages/*` | 21 |
| 其中：静态资源 `/static/*` | 9 |

后端命名风格（`/getInfo`、`/system/*`、`/sysTodoList`、`/sysDynamicTable`、`/database/*`、
`removeByrId`、`batchSave`）+ 自定义头 `sysType: 3`，符合 **RuoYi（若依）系 Java 后端**的典型结构。
*注：包内仍未检索到字面量 `ruoyi`，该判断为结构推断，非直接证据；但新增了「`/login` 返回结构 + `/getInfo` 权限点」这一 RuoYi 特征接口组合作为旁证。*
*同时确认：**未发现任何请求签名、加密或防重放机制**——`request()` 层只做 token 注入与 GET 参数拼接。*

### 3.12 实测记录

| 接口 | 方法 | 实测结果 | 关键返回 |
|---|---|---|---|
| `/login` | POST | ✅ 200 | `code=200`、`userId=32807`、`mustUpdatePwd=false`、返回有效 `token` |
| `/lesson/class/stuMyClasses` | GET | ✅ 200 | 1 条班级：`deptId=20018919`、`deptName=科学与技术创新1班`、`stuNumber=35`、`leader=于心宇,付贵友` |
| `/lesson/class/myClassDetail/20018919` | GET | ✅ 200 | 班级详情：`teacherNum=34`、`studentNum=35`；返回教师数组和学生数组，含账号、姓名、性别、头像等字段 |
| `/lesson/class/myTeachClassStu/20018919` | GET | ✅ 200 | 当前返回 `data=[]`（空数组） |

> 测试账号：`H202503018`。
> 脚本：[login.js](file:///c:/Users/yang/Desktop/nix/api/login.js)、[myClasses.js](file:///c:/Users/yang/Desktop/nix/api/myClasses.js)、[myClassDetail.js](file:///c:/Users/yang/Desktop/nix/api/myClassDetail.js)、[myTeachClassStu.js](file:///c:/Users/yang/Desktop/nix/api/myTeachClassStu.js)；
> [token.js](file:///c:/Users/yang/Desktop/nix/api/token.js) 默认复用 `info.txt` 中的 token，失效时才重新登录。

---

## 4. 页面结构（21 个路由）

```
/pages/home/index
/pages/profile/index
/pages/attendance/index
/pages/attendance/record
/pages/class/index
/pages/consumptionAnalysis/consumptionAnalysis
/pages/consumptionAnalysis/consumptionAnalysisList
/pages/consumptionAnalysis/consumWebView
/pages/IPass/index
/pages/IPass/detail
/pages/IPass/record
/pages/news/index
/pages/todo/index
/pages/weekCookbook/weekCookbook
/pages/appointmentMenu/appointmentMenu
/pages/nutritionKnowledgeColumn/index
/pages/nutritionKnowledgeColumn/detail
/pages/stuHoliday/index
/pages/stuHoliday/stuHoliday
/pages/webview/index
/pages/customAppWebview/index
```

功能域：首页、个人中心、考勤（列表/记录）、班级、消费分析（3 页）、一卡通（首页/详情/记录）、
新闻、待办、周食谱、预约菜单、营养知识（列表/详情）、学生假期（2 页）、通用 WebView 容器（2 个）。

`consumWebView` 页面内硬编码了 H5 地址：

```js
webUrl: "https://portal.haierschool.cn/pad/#/pages/consumptionAnalysis/consumptionAnalysisList"
```

---

## 5. APK 内部结构

### 5.1 整体

| 项 | 值 |
|---|---|
| ZIP 条目数 | 774 |
| REA 产物图节点数 | 736 |
| 产物图边数 | 774 |
| 完整性冲突 | 0 |
| `format` / `kind` | `apk` / `archive` |

顶层分布：

| 顶层目录 / 文件 | 条目数 |
|---|---|
| `res/` | 597 |
| `assets/` | 124 |
| `META-INF/` | 33（androidx 各库 `.version` 标记） |
| `lib/` | 11 |
| `io/` | 3 |
| `dc/` | 1 |
| `resources.arsc` / `classes*.dex` / `AndroidManifest.xml` | 各 1 |

### 5.2 DEX

| 文件 | 大小 | 内容 |
|---|---|---|
| `classes.dex` | 9.32 MB | DCloud 5+ Runtime + androidx |
| `classes2.dex` | 378 KB | 补充库（support-v4、Glide、MediaPicker 等） |
| `classes3.dex` | 5 KB | 少量类（`deviceidservice` / `opendeviceidlibrary` 等） |

> **关键判断**：dex 中的 URL 全部指向 DCloud 官方域名，**无任何业务接口**。
> 业务接口 100% 位于 JS（或 weex）资产中。

JADX 全量反编译实测：三个 dex 合计 **3,579 个类**，其中应用自有包 `com.hnyschoolpad.haier` 下
**仅 5 个类**（详见 1.3），其余全部为 DCloud 5+ Runtime、Weex、androidx、Glide/Fresco 等框架代码。
引擎报告 `signature_verification: not_performed`（未做签名校验），`heap_limit_mib: 7908`、`worker_count: 1`。

### 5.3 原生库（`lib/`）— 仅 32 位

全部 11 个 `.so` 均只存在于 `lib/armeabi-v7a/`，**没有 `arm64-v8a`**：

| 文件 | 大小 | 推测用途 |
|---|---|---|
| `libweexjss.so` | 8,933,420 | Weex JS 引擎（ScriptEngine） |
| `libweexcore.so` | 963,992 | Weex 核心 |
| `libc++_shared.so` | 600,852 | C++ 运行时 |
| `libsecsdk.so` | 505,688 | 安全 SDK |
| `libnative-imagetranscoder.so` | 251,516 | Fresco 图像解码 |
| `libgifimage.so` | 128,948 | GIF |
| `libpl_droidsonroids_gif.so` | 46,732 | GIF |
| `libnative-filters.so` | 13,960 | Fresco 滤镜 |
| `libimagepipeline.so` | 9,900 | Fresco 管线 |
| `libweexjsb.so` / `libweexjst.so` | 3,096 / 3,096 | Weex JS 线程 |

> 该包**不含 64 位原生库**，在仅支持 64 位的设备上无法安装；
> 且 `usesCleartextTraffic` 已开启，允许明文 HTTP。

### 5.4 assets（124 项）

业务资产根目录：`assets/apps/__UNI__104610A/www`（107 项）。核心文件：

| 文件 | 字节数 | 作用 |
|---|---|---|
| `assets/apps/__UNI__104610A/www/app-service.js` | 2,761,650 | **业务逻辑主体** |
| `…/www/app-view.js` | 624,460 | 视图层运行时 |
| `…/www/view.umd.min.js` | 400,885 | uni-app view 层 |
| `…/www/__uniappquill.js` | 211.5 KB | Quill 富文本 |
| `…/www/__uniappes6.js` | 51.4 KB | ES6 兼容层 |
| `…/www/app-config-service.js` | 5,798 | 运行配置 |
| `…/www/app-config.js` | 1,513 | webpack runtime |
| `…/www/manifest.json` | 1.0 KB | 应用清单 |
| `…/www/__uniappview.html` | 0.8 KB | 启动页 |
| `…/www/uni_modules/qiun-data-charts/static/app-plus/echarts.min.js` | 747,514 | ECharts |
| `assets/data/dcloud_properties.xml` | 3,025 | 5+ 模块配置 |
| `assets/data/dcloud_control.xml` | 118 | 5+ 运行控制 |
| `assets/data/dcloud_error.html` | 2,953 | 错误页 |
| `assets/data/dcloud3.dat` | 582 | 基座/授权数据 |

5+ 运行时 JS（顶层 `io/dcloud/`）：

| 文件 | 字节数 |
|---|---|
| `io/dcloud/all.js` | 164,713 |
| `io/dcloud/weexUniJs.js` | 160,454 |
| `io/dcloud/uni-app-service.js` | 12,722 |

### 5.5 主要静态资源

| 文件 | 大小 |
|---|---|
| `res/drawable/splash.png` | 1.95 MB |
| `www/static/image/components/frame-bg-top.png` | 1.93 MB |
| `www/static/image/homePage/swiper_default.png` | 1.91 MB |
| `www/static/image/components/frame-bg-bottom.png` | 484.1 KB |
| `www/static/image/appicon/icon1024.png` | 482.1 KB |
| `www/static/image/homePage/newslist_bg.png` | 390.5 KB |
| `www/static/image/homePage/service_bg.png` | 290.9 KB |
| `www/static/font/FZZDHJW.TTF` | 1.97 MB |
| `www/static/font/WDCHT.ttf` | 1.79 MB |
| `www/assets/uniicons.b6d3756e.ttf` | 34.9 KB |
| `assets/fonts/dcloud_iconfont.ttf` / `unincomponents.ttf` | 2.3 KB / 4.3 KB |

### 5.6 第三方库

| 库 | 识别依据 |
|---|---|
| ECharts + zrender | `uni_modules/qiun-data-charts/.../echarts.min.js`、zrender LICENSE 链接 |
| Quill | `__uniappquill.js`、`__uniappquillimageresize.js` |
| moment.js | moment 警告文档链接、locale 代码 |
| uView UI | `$refs.uForm.clearValidate()`、`this.$refs.uForm.children`、`u-view` / `uview` 标识符 |
| uni-id（uniCloud） | `x-serverless-sign`、`uni_id_token`、`spaceId` 校验逻辑 |
| Weex | `libweex*.so`、`com.taobao.weex.WXGlobalEventReceiver` |
| Fresco / Glide | `libimagepipeline.so`、`libnative-imagetranscoder.so` |
| com.dmcbig.mediapicker | `PickerActivity` / `PreviewActivity` |
| 自定义 uni_modules | `telly-nav-bar`、`hb-empty` |

---

## 6. AndroidManifest 信息

### 6.1 权限

```
android.permission.INTERNET
android.permission.ACCESS_NETWORK_STATE
android.permission.CAMERA
android.permission.READ_EXTERNAL_STORAGE
android.permission.WRITE_EXTERNAL_STORAGE
android.permission.BIND_JOB_SERVICE
com.huawei.android.launcher.permission.CHANGE_BADGE
com.vivo.notification.permission.BADGE_ICON
com.miui.securitycenter.permission.AppPermissionsEditor
com.asus.msa.SupplementaryDID.ACCESS
freemme.permission.msa
```

### 6.2 组件与配置

| 类别 | 内容 |
|---|---|
| Application | `io.dcloud.application.DCloudApplication` |
| 入口 Activity | `com.hnyschoolpad.haier.HaierPandoraEntry`、`io.dcloud.PandoraEntryActivity` |
| WebView Activity | `io.dcloud.WebAppActivity`、`io.dcloud.WebviewActivity` |
| 媒体 Activity | `com.dmcbig.mediapicker.PickerActivity` / `PreviewActivity`、`io.dcloud.feature.gallery.imageedit.IMGEditActivity`、`io.dcloud.feature.nativeObj.photoview.PhotoActivity` |
| Service | `io.dcloud.ads.base.service.DownloadService`、`io.dcloud.ProcessMediator` |
| Receiver | `io.dcloud.common.adapter.io.DownloadReceiver`、`com.taobao.weex.WXGlobalEventReceiver` |
| FileProvider | `com.hnyschoolpad.haier.dc.fileprovider`、`io.dcloud.common.util.DCloud_FileProvider` |
| Intent | `MAIN` / `LAUNCHER`；`VIEW` + `BROWSABLE` + `DEFAULT`（含自定义 `scheme`，支持深链唤起） |

清单属性键（`manifest_strings.txt` 共 92 条）中出现：
`package`、`versionCode`、`versionName`、`uses-sdk`、`minSdkVersion`、`targetSdkVersion`、
`compileSdkVersion`、`compileSdkVersionCodename`、`platformBuildVersionCode`、`platformBuildVersionName`、
`usesCleartextTraffic`、`debuggable`、`largeHeap`、`allowBackup`、`allowClearUserData`、
`extractNativeLibs`、`hardwareAccelerated`、`supports-screens`、`appComponentFactory`、
`queries`、`dcloud_appkey`、`android.max_aspect` 等。

> 上述键的**具体数值**已由 JADX 通道完整解析 AXML 属性区，见 **1.1** 节
> （`minSdkVersion=21` / `targetSdkVersion=30` / `compileSdkVersion=30` / `versionCode=22` /
> `versionName=1.21` / `dcloud_appkey=99bf68a9865510ae6ba274d0c5313605` / 深链 scheme `h56131bcf`）。
> 本节组件清单亦经 JADX 反编译交叉核对。

---

## 7. 本地存储与凭证

| 存储键 | 用途 |
|---|---|
| `token` | 业务后端 Bearer Token（`Authorization` 头） |
| `userInfo` | 用户信息（Vuex `mapGetters(["userInfo"])`） |
| `uni_id_token` / `uniIdToken` | uni-id 用户体系令牌 |
| `uni_id_token_expired` | uni-id 令牌过期时间 |
| `access_token_<spaceId>` | uniCloud accessToken |

**未发现**：硬编码 IP；硬编码 uniCloud `spaceId` / `clientSecret`；
硬编码第三方 AK/SK；硬编码账号口令。

---

## 8. 方法与局限性

### 8.1 本次使用的方法

**第一轮（字符串取证）**

1. `rea open_binary haier.apk` → 确认 `format=apk` / `kind=archive`，计算 SHA-256
2. `rea inspect_artifact` → 完整产物图（736 节点 / 774 边 / 0 完整性冲突 / 覆盖 2285 项）
3. `rea binary_session` → 确认服务端身份（rea-agents 6.8.0）与能力可用性
4. 从 ZIP 中央目录导出条目清单（774 条），统计顶层分布
5. 抽取 `classes*.dex`、`resources.arsc`、`AndroidManifest.xml` 做字符串取证
6. 抽取 `app-service.js` 等 JS 资产，用正则提取 URL、路径字面量、请求层配置、存储键、请求头

**第二轮（JADX 深反编译通道）**

7. 校验引擎 JAR：`jadx-headless-mcp-0.7.1-all.jar`（42,619,858 字节）SHA-256
   `6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75`，与 release 自带
   `.sha256` 逐字节一致
8. 通过 `REA_JADX_MCP_JAR` + `JAVA_HOME`(JDK 21.0.7) 注入引擎，`TEMP`/`TMP` 重定向到
   `C:\Users\yang\.rea\tmp`（避开 `%USERPROFILE%\AppData\Local\*` 的 DACL 异常子树）
9. `rea inspect_android_package` → 归一化类/资源统计（`class_count=3579`、`resource_count=774`）
10. `rea search_android_classes` → 定位应用自有包，确认 `com.hnyschoolpad.haier.*` 仅 5 个类
11. `rea inspect_android_class` → 逐类还原成员（`AppPlugin` / `UserInfo` / `BuildConfig` 等）
12. 用 Node 脚本 `extract.js` 对 `app-service.js` 做调用点级提取，得到 56 个 `request()`
    调用点的 HTTP 方法与关键入参（规避 PowerShell 正则转义问题）

### 8.2 局限

- 本次结论属**静态分析**（字符串取证 + JADX 反编译），**非运行时验证**。
- **接口的方法级信息（HTTP 方法 / 关键入参 / 动态路径）已获取**（见第 3 章），此前
  「未配置 JADX 通道」的限制已解除。
- 仍**未获取**的内容：
  - 请求体 / 响应体的**完整字段结构**（仅能从调用点看到传参名，未见后端 DTO 定义，
    因为接口定义在后端 Java，APK 内不含）
  - 是否存在服务端侧的签名/风控（客户端侧已确认**无**签名、加密、防重放逻辑）
  - 鉴权失败处理逻辑、每个接口所需的后端权限点
- `AppConfig` 中**只发现一个** baseURL，未见测试/预发环境切换逻辑。
- 章节 3.11 中「RuoYi 后端」为命名风格 + 特征接口组合的**结构推断**，包内无 `ruoyi` 字面量。
- 章节 6.2 中组件清单来自 AndroidManifest 字符串池；由于 AXML 字符串带长度前缀，
  个别条目前部可能被截去 1 个字节（已在整理时按语义还原，未影响判定）。
- JADX 通道报告 `signature_verification: not_performed`，**APK 签名未校验**。

### 8.3 建议的后续步骤

| 目标 | 手段 |
|---|---|
| 获取接口请求/响应完整字段结构 | 抓包（Charles / mitmproxy）观察真实报文；注意 `usesCleartextTraffic=true` 已开启明文 |
| 验证接口真实行为与鉴权 | 动态验证：以 `/login` 换 token，再按第 3 章方法/入参逐条复现 |
| 还原接口调用代码可读化 | 对 `app-service.js` 做 js-beautify/prettier 格式化后按模块检索 |
| 校验签名与 SDK 区间 | `rea inspect-apk-signature`（APK 已在本地，通道已可用） |
| 深挖原生层 | dex 已反编译完毕（仅 5 个自有类），无进一步可挖业务逻辑 |

---

## 附录 A：证据文件位置

**第一轮中间产物**保存在 `C:\Users\yang\AppData\Local\Temp\haier_x\`：

| 文件 | 内容 | 条数 |
|---|---|---|
| `entries.txt` | APK ZIP 条目清单（`字节数<TAB>路径`） | 774 |
| `toplevel.txt` | 顶层目录分布统计 | 11 |
| `urls.txt` | dex + resources.arsc 中的 URL 分组统计 | 17 |
| `js_urls.txt` | JS 中的 URL 分组统计 | 20 |
| `js_paths.txt` / `api_all.txt` | 路径类字面量全量（含出现次数） | 89 |
| `pages.txt` | 页面路由 | 21 |
| `haierschool.txt` | `haierschool.cn` 相关字面量 | 2 |
| `ctx_portal.txt` | `portal.haierschool.cn` 上下文（webUrl 等） | — |
| `ctx_base.txt` | baseURL / 请求层配置上下文（5,404 字符） | — |
| `ctx_auth.txt` | 鉴权 / token 相关上下文 | — |
| `socket.txt` | JS 中完整 URL 字面量 | 9 |
| `manifest_strings.txt` | AndroidManifest 字符串池 | 92 |
| `ips.txt` | IP 地址扫描结果（空） | 0 |
| `www/` | 从 assets 抽取的 JS / JSON / XML 配置 | 18 |

**第二轮（JADX / REA）产物**保存在 `C:\Users\yang\.rea\`：

| 路径 | 内容 |
|---|---|
| `jadx\jadx-headless-mcp-0.7.1-all.jar` | JADX 引擎（已校验哈希） |
| `jadx\jadx-headless-mcp.sha256` | release 官方校验文件 |
| `tmp\` | 隔离的 TEMP 目录（DACL 自检 `healthy`） |
| `out\pkg.txt` | `inspect-android-package` 完整输出（26,864 字节） |
| `out\extract.js` | 56 个 `request()` 调用点提取脚本（Node） |
| `out\cls_app.txt` | 应用自有类检索结果（`com.hnyschoolpad.haier` 包下 5 个类） |
| `out\class_AppPlugin.txt` | `AppPlugin` 反编译详情 |
| `out\class_UserInfo.txt` | `UserInfo` 反编译详情 |
| `out\class_BuildConfig.txt` | `BuildConfig` 反编译详情 |
| `out\class_HaierPandoraEntry.txt` | `HaierPandoraEntry` 反编译详情 |

## 附录 B：关键证据摘录

```
sha256            : 20aa847da8361fde672d0ae74937f94e48e832228ead0ecfe96f0bbabd30a825
format / kind     : apk / archive
zip entries       : 774
graph nodes/edges : 736 / 774
integrity         : 0 contradictions
baseURL           : https://portal.haierschool.cn/v/
h5 url            : https://portal.haierschool.cn/pad/#/pages/...
header.sysType    : 3
timeout           : 60000 ms
auth              : Authorization: Bearer <store:token>
unicloud endpoint : https://api.bspapp.com  |  https://api.next.bspapp.com
unicloud path     : /client  (POST, x-serverless-sign)
uni-cloud fn      : /functions/invokeFunction
--- JADX（第二轮）---
jadx engine       : jadx-headless-mcp 0.7.1  (JDK 21.0.7)
jar_sha256        : 6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75
source_revision   : 5844800a486d2248fa949b74c9896285f5b54de2
bridge_sha256     : e5044a8312dd0731f53af3f095508b3e5cff54df6b971c95d4305e2f39b4fa30
class_count       : 3579   (自有包 com.hnyschoolpad.haier.* 仅 5 类)
resource_count    : 774
signature_verify  : not_performed
minSdk/targetSdk  : 21 / 30
versionCode/Name  : 22 / 1.21
dcloud_appkey     : 99bf68a9865510ae6ba274d0c5313605
deep-link scheme  : h56131bcf
request() calls   : 56   (GET 46 / POST 7 / PUT 1 / DELETE 2)
```
