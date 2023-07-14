# CloudFlare DDNS

一个基于 CloudFlare api 的 shell 脚本，自动更新 dns 的 ipv6 记录

# 开始使用

## 前期准备

- 拥有一个域名并使用 Cloudflare 的 DNS 服务器。
- 访问 [CloudFlare](https://dash.cloudflare.com/) 获取你的区域 ID
- 在[此处](https://dash.cloudflare.com/profile/api-tokens)创建一个 `api token` 
- 下载 `updateIpv6.sh` 并根据注释修改 `zoneId` `recordName` `apiKey` 字段

## 开始使用

运行:

``` shell
sh ./updateIpv6.sh
```

这将首先通过网卡获取 ipv6 地址，并同步到 dns 记录。

如果不存在此类记录，将创建一个。

如果记录已设置为预期的 ip，则不执行任何操作。

## 宝塔面板

在计划任务里添加 `Shell 脚本` 复制 `updateIpv6.sh` 里的全部类容粘贴进去

名称随意，执行周期改为 `N分钟` ，然后输入 `10` 分钟，点击添加任务

在`任务列表`里执行一遍，没报错就行了

> 报错的话自己看看错哪了，一般只改变量就行

# 注意

您可以使用 [crontab](https://linuxconfig.org/linux-crontab-reference-guide) 或 [宝塔](https://www.bt.cn/new/index.html) 定期执行它。

不要滥用，cloudflare 限制 API 调用速率限制为每 5 分钟 1200 个请求。

本项目基于 [imki911/DdnsOnCloudFlare](https://github.com/imki911/DdnsOnCloudFlare) 修改而来，汉化了文档及注释，并修改为单文件以方便在宝塔面板中使用

鉴于国内基本不存在 ipv4 公网，因此去除了 ipv4 的部分，如有需要可使用[原项目](https://github.com/imki911/DdnsOnCloudFlare)

此项目使用 GPL-3.0 许可证 开源