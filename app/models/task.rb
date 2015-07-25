require 'movie_spider'
require 'spreadsheet'
require 'net/http'
require 'uri'
Spreadsheet.client_encoding = 'UTF-8'
class Task
  include Mongoid::Document
  include Mongoid::Timestamps

  TIEBA_HASH = {
    "我们15个" => {name:"我们15个",link:"http://tieba.baidu.com/f?kw=%E6%88%91%E4%BB%AC15%E4%B8%AA&ie=utf-8&pn=0",limit:nil},
    "真正男子汉" => {name:"真正男子汉",link:"http://tieba.baidu.com/f?kw=%E7%9C%9F%E6%AD%A3%E7%94%B7%E5%AD%90%E6%B1%89&ie=utf-8&pn=0",limit:nil},
    "奇葩说" => {name:"奇葩说",link:"http://tieba.baidu.com/f?kw=%E5%A5%87%E8%91%A9%E8%AF%B4&ie=utf-8&pn=0",limit:nil},
    "爸爸去哪2" => {name:"爸爸去哪2",link:"http://tieba.baidu.com/f?kw=%E7%88%B8%E7%88%B8%E5%8E%BB%E5%93%AA%E5%84%BF&ie=utf-8&pn=0",limit:nil},
    "爱上超模" => {name:"爱上超模",link:"http://tieba.baidu.com/f?kw=%E7%88%B1%E4%B8%8A%E8%B6%85%E6%A8%A1&ie=utf-8&pn=0",limit:nil},
    "你正常吗" => {name:"你正常吗",link:"http://tieba.baidu.com/f?kw=%E4%BD%A0%E6%AD%A3%E5%B8%B8%E5%90%97&ie=utf-8&pn=0"},
    "百万粉丝" => {name:"百万粉丝",link:"http://tieba.baidu.com/f?kw=%E7%99%BE%E4%B8%87%E7%B2%89%E4%B8%9D&ie=utf-8&pn=0",limit:nil},
    "牵手爱情村" => {name:"牵手爱情村",link:"http://tieba.baidu.com/f?kw=%E7%89%B5%E6%89%8B%E7%88%B1%E6%83%85%E6%9D%91&ie=utf-8&pn=0",limit:nil}
  }

  #我们15个预警关键词
  WARN1 = %w(卸载 不要 假 没意思 无语 无聊 看不了 怎么回事 APP 声音 不真实 导播 宫心计 偏离 没看懂 慢 恶搞 剧本 受骗 违约 失望 质疑 作秀 农村 完蛋 中断 差 散漫 消极 负能量 演 删 )
  #真正男子汉预警关键词
  WARN2 = %w(假 作秀 哗众取宠 不真实 极端 纪录 质疑 )
  #奇葩说预警关键词
  WARN3 = %w(出场费 打酱油 没文化 鸡肋 低俗 暗讽 撕逼 不爽 科学 悲哀 臆断 素质 停播) 
  #我们15个卷入关键词
  ENTANGLE1 = %w(真实 生活 实验 发展 团结 创造 资源 理想 信任 合作 生存 财富 钱 创新 理念 重建 探索 坚持 规则 淘汰 精神 理解 负责 渴望 回归 自然 提高 直播 参加 报名 劳动 体验 指挥 经济 规划 矛盾 假 没意思 剧本 质疑 作秀 失望 不真实 赞 棒 喜欢 支持 舒服 吐槽 演 挑拨 女朋友 男朋友 夫妇 淫荡 撕逼 )
  #真正男子汉卷入关键词
  ENTANGLE2 = %w(部队 军营 战士 兵 训练 军人 真实 兵种 军旅 韩国 挑战 精神 男人 艰苦 战友 坚持 军队 生活 正能量 荣誉 自豪 真实 暖心 阳光 勇往直前 感人 有趣 可爱 成长 优秀 光荣 感动 霸气 不舍 魅力 外刚内柔 硬汉 柔情 爱国 责任 热血 真性情 自信 坚毅 出色 军魂 梦想 韩版) 
  #奇葩说卷入关键词
  ENTANGLE3 = %w(说话 娱乐 话题 辩题 关注 评委 嘉宾 选手 观点 表达 口才 价值 思考 语言 辩论 逻辑 口才 社会 热点 正能量 逼格 辩论 )
  #我们15个节目关键词
  PROGRAM = %w(真实 生活 实验 发展 团结 创造 资源 理想 信任 合作 生存 财富 钱 创新 理念 重建 探索 坚持 规则 淘汰 精神 理解 负责 渴望 回归 自然 提高 直播 参加 报名 劳动 体验 指挥 经济 规划 矛盾 正能量 ) 
  #我们15个剧情关键词
  STORY   = %w(洗衣 洗头 做饭 唱歌 耕地 种菜 电脑 马桶 奶牛 设计 牛奶 耕地 表演 电话 生理 粮食 食物 造型 厨房 卫生巾 灶台 煮饭 野菜 铁锹 卫生 木头 开垦 石头 怀孕 木板 床 洗澡 种植 教练 饮食 牛 奶瓶 煤气罐 雨 牛粪 吵架 早饭 撕逼 补充 洗澡 有水军 解锁 钓鱼 粪池 破产 欠钱 粮食 牛粪 培训 招学员 手机 绝食 病 姿势 违规 皮具 工艺品 农场主 红薯 哭 皮制品 沈老板 洗白 许巍 歌曲 烧饭 偷吃 外挂 项链 湿疹 )
  #我们15个娱乐关键词
  DISPORT = %w(勾引 暧昧 夫妇 露胸 脑残粉 诱惑 八婆 销魂 消遣 爽 )
  #我们15个人物特征关键词
  FEATURE = %w(希望 不错 肯定 解决 期待 好看 真心 完全 规则 适合 明白 出现 好多 作为 团结 精神 发展 不同 节奏 漂亮 大师 确实 机会 成功 精彩 努力 帮忙 负责 道德 理解 清楚 技能 娱乐 快乐 欢迎 渴望 光荣 永远 教育 建设 默默 代表 感动 合适 梦想 认真 合理 小心 舒服 保证 创造 人才 理想 人民 勤快 务实 回归 热血 自然 明确 超级 幸福 建立 值得 发挥 效果 本事 和谐 推荐 标准 牺牲 出名 战友 开启 老实 帮助 福利 统一 聪明 规矩 完美 完成 尊重 贡献 积极 具体 英雄 凤凰 吸引 彻底 佩服 指导 感谢 祝福 达到 打扮 大型 包容 正确 天真 强大 平定 青春 丰富 打开 技术 进步 足够 保护 补充 雪亮 经典 展现 创意 拯救 方便 独立 充满 严肃 提高 改善 宝贝 文明 收获 典型 好听 有趣 获得 完整 健康 服从 成长 懂事 利益 放心 伟大 改造 开放 理性 勇气 客观 熟悉 满足 干净 艰苦 美丽 创业 对不起 拜托 羡慕 实用 激情 仔细 邀请 愉快 致敬 威武 恭喜 优秀 凉快 气质 厨师 敏感 请教 惊喜 实话 民主 赞助 担当 坚决 奖励 大事 新鲜 优势 犀利 高手 好人 赞同 轻松 欣赏 清晰 心思 财富 系统 带领 无限 创收 纪念 奋斗 初衷 沸腾 充分 幻想 温柔 的确 致富 打击 大众 公开 欢乐 高潮 奇迹 成绩 动力 希有 风格 红色 达成 耐心 长远 传统 美好 理智 探讨 带头 大量 美美 全面 科学 本色 擅长 一致 追求 技巧 亲爱 晶莹 辅助 胜利 窗口 乐趣 协调 豪华 成果 开发 热闹 帅气 保障 节约 深度 培养 严格 做人 自信 良心 凝聚力 感人 稳定 承担 救援 厚道 呈现 入选 解救 花絮 超越 开导 贺电 表扬 果断 精华 成立 吃苦耐劳 进展 召唤 活跃 选拔 出头 多数 特色 珍惜 想念 前进 怀念 简易 陪伴 伴侣 友谊 硬汉 保养 乐观 真诚 天理 名牌 正义 巨大 心声 长久 奉献 优点 小康 和平 魄力 向往 勤奋 精英 极致 适当 深刻 精力 大胆 幽默 心灵 细心 引导 机智 见解 魅力 迅速 不愧 奖金 自觉 悠闲 功劳 齐全 成就 大局 亲人 高度 增长 探索 首要 用心 冷静 名人 长者 赞成 教养 热情 盈利 趣味 平安 温暖 保密 见识 干脆 尽情 长处 尽力 了不起 信心 改观 纯粹 名言 高级 清醒 享福 收益 相反 滚滚 专家 鉴定 激发 愿望 合群 难得 感恩 大权 温和 毅力 红包 优美 口才 敢于 决心 阐述 鼓励 信仰 祝贺 革命 创作 境界 恢复 宽容 正经 回报 风范 顺眼 辅导 详细 鲜明 承诺 推广 顺利 满意 整齐 才华 高尚 有力 强者 支援 地道 权威 服务 落实 妖娆 一心 改革 自主 称号 讲究 意志 斗争 万岁 积极性 报酬 好评 准确 高大 感言 快速 夺冠 神圣 访问 热烈 热爱 跨越 柔情 好处 平等 修好 提升 天然 成名 扩大 士气 解惑 在理 乐意 任劳任怨 黄金 泰山 自立 想象力 彩礼 名气 信任 机动 觉悟 齐心 透彻 脚踏实地 尊敬 礼貌 志同道合 理直气壮 粉红 示范 巨人 真理 好事 整洁 灵感 先进 平静 指教 熟练 人格 有效 亲切 无敌 操心 好感 可靠 合法 清华 尊严 创新 查看 民意 全新 用于 从不 直爽 良好 充足 战胜 明智 头等 带动 无比 好使 劳模 好强 赢得 人和 才能 深情 发达 节省 正当 奖品 理顺 清净 发财 有劲 大好 百倍 宁静 感染 体贴 获取 揭晓 独特 圣人 感激 推进 热心 开辟 精明 开通 高档 创造力 崇拜 纯洁 涵养 可行 及时 修养 可观 探访 新颖 火花 求救 知名 人权 烈士 著名 无意 爱国 发起 好心 自豪 检举 男儿 名手 康复 拥护 专心 合格 富有 解放 飙升 帮手 善意 情愫 辅佐 不赖 惦记 利于 红旗 树立 荣誉 打通 耿直 完善 顶用 明了 正轨 平反 大作 甘心 得分 吸引力 打破 用功 得当 心愿 高材生 红花 真话 利索 幸运 较真 慎重 清洁 一流 东风 彩虹 气候 庆祝 受益 勇士 非凡 美人 浪漫 挚爱 前辈 觉醒 生财 确切 改进 诚意 热门 开朗 光明 优越 晋级 节操 赋予 趣事 深入 坚定 权益 抗战 赤子 绝技 唤醒 爱护 风趣 争气 虚心 志愿 细致 光顾 平整 滋润 大力 淳朴 抬举 问候 因地制宜 切实 进取 牢固 榜样 明眼人 缓解 锐气 模范 精通 察觉 津津有味 老黄牛 喜庆 发家 舒坦 对劲 见效 赶上 远见 流行 分明 救济 繁华 吉祥 安定 颂歌 稳固 崛起 谦虚 促进 称职 精选 推心置腹 友好 太平 明镜 带劲 好话 发明 结实 发光 长辈 点头 生动 调和 火热 威风 壮大 造就 立功 友爱 宝藏 刻苦 仙境 别致 期望 活力 翻身 敬佩 史无前例 感悟 美味 扶持 报喜 天使 美景 谅解 壮观 净化 期盼 迎接 鉴别 吃香 思念 坚守 真情 继承 复苏 机遇 宝贵 才子 顿悟 苍穹 友情 真言 飞翔 平和 底蕴 聆听 精髓 精品 进化 定心丸 气势 宣扬 信服 深思 灵活 情谊 歌唱 血气方刚 仁慈 立志 肩负 重托 铁汉 奇兵 启示 雄心 千锤百炼 刚性 娇小 特效 口碑 精心 红豆 一往无前 憨厚 出息 精确 拓展 欣欣 救助 正直 安然 宏大 威望 长征 花朵 推动 恳求 雷厉风行 老练 开窍 无与伦比 丰满 赐教 遐想 顺心 全力以赴 专注 率真 美化 显著 天赋 修长 凉爽 激昂 和易 可嘉 榜首 体谅 景观 精细 勤勤恳恳 美观 丰收 底气 捷径 汹涌 便于 强化 发掘 轻快 打气 激励 收复 吉利 景色 柔和 潇洒 保全 孝顺 无私 顶峰 风光 在行 郑重 保险 耐用 恳请 有名 亲和力 明朗 清高 斗志 谨慎 表率 献身 英勇 奇妙 重视 坚忍 茂盛 果敢 迷人 大路 提神 安宁 策略 建设性 完美无缺 满分 起早贪黑 清静 高贵 本领 对头 锋利 保重 重任 资助 才女 创造性 爱惜 飘逸 安稳 光明正大 温情 心血 耐性 健全 才学 恩爱 放手 仙女 隐蔽 沉思 带头人 深意 惬意 有理 坦诚 甘愿 夸奖 大吉 英明 盼望 畅销 美妙 美酒 做主 试金石 清新 优雅 热火朝天 拼搏 好汉 简短 光临 扎实 超凡 盛产 盛开 侃侃 志向 天才 慷慨 持久 宾馆 逼真 新意 恋情 胜任 祝愿 新生 信奉 通才 名句 法治 远大 成才 升华 能手 吉祥物 鉴赏 妩媚 可取 见好 荣耀 和气 应酬 君子 递交 知己 意愿 严密 宁死不屈 煊赫 至亲 仁义 超脱 打动 身体力行 狂欢 赞美 严谨 欢呼 揭发 灿烂 不惜 强手 晶晶 出色 解围 联手 荣光 恰当 遵循 志气 睿智 璀璨 先行 前锋 锋芒 巾帼 贴心 动人 安好 铁军 弘扬 力作 畅谈 汇集 老当益壮 大户 回味 稳重 改过 隆重 钢铁 盛大 讴歌 精致 极力 大方 忠实 纵横 娴熟 硬朗 借鉴 真切 流畅 挺身而出 缜密 妥善 韧性 兢兢业业 辛勤 完人 开拓 增强 择优 大度 健美 朴素 造福 埋头苦干 主心骨 顺畅 相知 直截了当 能干 细腻 直观 航向 发亮 苦心 本分 教导 高洁 快捷 飞快 温馨 繁茂 保送 贴切 名作 品德 威严 兵家 高昂 叮嘱 忠厚 捐赠 生龙活虎 前沿 客气 沐浴 投缘 变通 珍品 民心 荣登 三好 富裕 清泉 点缀 培育 清心 多谢 功绩 鼓舞 慈善 正派 节能 正道 诚恳 舒适 开张 定准 胆量 婉转 改良 成效 良田 勤恳 有助 诗意 众望 无量 儒雅 风度 知音 茁壮 童真 知趣 省事 上进 第一线 素养 友善 状元 显现 自如 持之以恒 互利 互惠 督促 中肯 正气 大姓 旺盛 青天 恩人 优待 普照 得主 积德 慈爱 天分 无尽 兴旺 人缘 成材 在握 苗子 开山 来劲 上好 叮当 超人 热心肠 长进 富贵 肥美 对称 绝招 豁达 大雄 一心一意 安分 坚挺 搭救 繁星 诚心 出众 精辟 劳苦功高 洗礼 效仿 叫好 好过 口若悬河 晴空 婀娜 紧凑 通畅 安详 表里如一 健谈 见地 奋进 集锦 扩展 盛情 如愿 深邃 绝顶 魔力 水灵 轰轰烈烈 崭新 幽静 进军 永恒 坚韧不拔 开创 雄赳赳 气昂昂 攀登 静谧 意气风发 矫健 绝世 盈盈 碧绿 圣地 行家 柳暗花明 英气 大道 开阔 实惠 纪念册 春风 精灵 披荆斩棘 澄清 忠贞 老手 稳健 大雅 机灵 陶然 贤惠 方舟 全才 留恋 至宝 花魁 庆典 名媛 伦理 上乘 活泼 取胜 益处 奔驰 福音 铿锵 遵从 自尊 补救 圣贤 包涵 入室 逍遥 抵抗 奖学金 绝唱 誓死 捍卫 美貌 才气 善事 内行 率先 大同 仰望 史诗 名列前茅 意气 仁厚 箴言 道地 法宝 真心诚意 甜头 进化论 推崇 可贵 光辉 义举 喝彩 宝剑 成仁 纯真 正规 爱慕 操守 德育 慈悲 从容 斗士 颂扬 永生 适用 诚实 喜悦 欢喜 奖杯 盛况 高举 有所作为 飞奔 风流 名士 风骨 知心 提倡 密友 称赞 尖锐 申冤 领先 博学 得力 般配 至上 佳话 有条有理 窍门 点拨 赠送 盛世 赞叹 堂堂 珍爱 舒畅 尽兴 恭候 嫩黄 名师 妙语 辩才 扼要 渊博 侃侃而谈 急智 不朽 甘于 千里马 留念 梦境 担任 勋章 憧憬 大白 联谊 心爱 倡议 誓言 战果 辉煌 恰到好处 奠基 担负 长城 盛赞 独创 旗手 依依 和蔼 标兵 奖章 正宗 珍藏 战绩 大厦 深远 事迹 刚毅 俏丽 感同身受 委托 就义 森森 报效 尖兵 欢快 圆满 神威 纪念馆 前途无量 深造 老前辈 欢笑 号角 英姿 青葱 清明 跃进 使命 敏锐 达标 酣睡 干练 悲壮 澎湃 护卫 锐利 展翅 和暖 旗帜 靠得住 突进 爆满 涌现 喜报 心安 敏捷 信用 颁布 英俊 势不可挡 面市 武艺 锦绣 鞠躬 强将 预祝 飞扬 雀跃 纪念品 绚烂 传家宝 好样儿的 发扬 动听 保健 事半功倍 通人 清凉 耐劳 取经 忘我 豪情 增进 激进 神气 神似 大寿 华丽 促成 财宝 地利 倾慕 朝气蓬勃 壮举 壮士 冒尖 奉行 忠心 秀丽 振作 打响 合算 救急 迸发 强项 命脉 真情实意 后盾 顽强 首创 粉饰 义气 筹集 能人 风采 直率 好转 纯正 明媚 含蓄 法制 享用 点明 美德 严明 威信 陶冶 情操 温顺 振奋 宝座 亲和 简洁 自强不息 采纳 辈出 名正言顺 浓厚 才智 质朴 优良 自重 辛劳 上流 盈余 灵性 浓郁 平稳 温文尔雅 多样 改过自新 强壮 纯朴 摆平 融洽 前导 远虑 科学家 大宝 优选 赋有 悠悠 排山倒海 心细 畅快 安乐 摈弃 孝敬 疼爱 谦虚谨慎 妙处 坚信 优惠 简略 大军 再接再厉 妥当 爽朗 摇篮 前景 振兴 开化 生根 喜闻乐见 井井有条 乐于 勇于 传授 绿化 莅临 金贵 创建 流通 晋升 随和 谦逊 知足 小心翼翼 保鲜 高才生 真谛 愉悦 充实 素雅 珍贵 主人翁 热火 放眼 洒脱 勇往直前 美名 部署 调解 闯劲 老成 特异 伴随 周全 生机 互助 精诚 均匀 多彩 自强 痛快 洁净 心服 重担 美感 舍弃 袅袅 春意 清香 沧海 芬芳 优先 干将 推举 明晰 来宾 并肩 奔赴 得胜 实事求是 富足 厚望 优质 出类拔萃 充盈 便利 捐助 定夺 胜诉 细长 聘请 典范 创办 伟人 喜好 繁荣 帅 兴奋 开心 支持 喜爱 勤劳 可爱 单纯 坚强 真实 实干 女神 加油 喜欢 善良 爱生活 智慧 美女 做事 萌萌哒 赞 棒 锻炼 坚韧 勇敢 汉子 沉稳 朴实 实事 实在 正能量 阴谋 踏实 成熟 全景 违规 顶起 心疼 潜水 不要脸 养老 苦中作乐 自娱自乐 懒 发呆 骂 作秀 臭美 脑残 疯子 装逼 淘汰 可怜 表演 不是好人 墨迹 狗腿 好鸟 演戏 八卦 爆出口 撒娇 不舒服 吐槽 矫情 打酱油 傻呆 憎 恨 无用处 作 废物 声音 浪费 简单 失望 吹牛 总是 无聊 出轨 一般 意见 坏话 废话 自私 失败 麻烦 吵架 随便 傻子 废人 作弊 控制 习惯 欺负 抱怨 打算 地主 恐怖 鄙视 扯淡 后悔 纸上谈兵 扫地 严重 拉拢 丢人 虚伪 得罪 暂时 缺少 生气 显示 崩溃 孤立 不对 丢脸 困难 变态 空谈 不是 是非 任性 做作 大爷 难受 出局 攻击 该死 专门 吓人 郁闷 完蛋 平凡 绑架 错误 懒散 打架 勾引 毛病 乱七八糟 错过 限制 批评 缺点 遗憾 费劲 笑话 策划 自以为是 勾心斗角 吃苦 寄生虫 破坏 缺乏 刺激 危机 侮辱 做梦 内幕 结局 霸气 土豪 吃亏 傀儡 反对 垃圾 暴君 挑拨 无知 烦人 野人 出事 后台 游手好闲 反感 转向 黑暗 议论 笨蛋 孤独 懒惰 疯狂 伤心 僵尸 祸害 嘴皮子 无能 娇气 尴尬 过分 消耗 漏洞 翻车 无耻 异想天开 厌恶 混乱 紧张 安心 伤害 平常 大兵 瞎扯 独裁 临时 手段 阴暗 幼稚 歧视 空话 空想 好高骛远 兵痞 幕后 谎言 混蛋 好逸恶劳 黑幕 懒汉 拉帮结伙 嫉妒 隐藏 心烦 联络 碰撞 残酷 难过 简陋 折磨 颠覆 恶意 瞎说 黄色 讨好 依赖 魔鬼 威胁 负担 消极 平淡 不满 可恶 发烧 荒芜 丧心病狂 打扰 泼妇 负面 误导 耽误 指手画脚 别扭 倒霉 阴谋 后果 散漫 弱点 点火 阴险 对得起 敌人 霸道 联合 下降 鬼子 绝境 麻痹 对抗 魔王 代沟 欠缺 邪恶 坏事 傻瓜 私心 指责 枯燥 模糊 累赘 懒虫 犹豫 耍滑 作呕 密谋 嫌弃 鬼胎 奢侈 无视 不利 差劲 复活 心寒 妖怪 妖精 辜负 烦恼 松散 扭曲 误解 抄袭 炮灰 辱骂 障碍 排斥 约束 受罪 浮躁 坏人 说教 收买 可耻 得逞 贫困 暴力 凌乱 被动 帮派 狭窄 骗子 绝望 算计 炫耀 白痴 流氓 白眼 争吵 误区 伪善 粗暴 入侵 相同 干涉 排挤 致命 反击 报废 结合 调戏 单调 低级 废品 悲伤 德行 死气沉沉 贬低 伪装 卖弄 平庸 屁话 嚼舌 暴跌 不屑 剥夺 专制 失误 包袱 调皮 偏激 拖后腿 刻薄 偏向 违背 低下 勉强 残忍 仇恨 批判 破灭 小人 事故 变相 小偷 排除 囚犯 凄凉 暴躁 搬弄是非 作假 泄密 揭露 病毒 风险 杂乱无章 不堪 叛变 出卖 不和 煎熬 打败 乏味 自大 自私自利 捣乱 脆弱 低头 张扬 寄生 坐享其成 污染 暧昧 狡诈 起哄 黑货 动摇 摆设 讽刺 痞子 标榜 变味 勾搭 不良 费力 受苦 耻辱 缺陷 功利 油水 主观 机械 不快 污蔑 低档 下场 贫穷 野心 愚蠢 放火 欺骗 压抑 逃亡 低俗 委婉 炎热 灾难 动用 偏见 猥琐 恶魔 诡辩 霸王 费解 风头 顶嘴 谣言 严厉 狗腿子 片面 冷漠 粗话 苛刻 恶劣 嫌疑 养尊处优 逞能 白食 残废 冷淡 羞耻 偏心 瞎话 嚣张 渺小 过时 后门 妄想 伸手 胡说 报复 拖累 施展 不劳而获 困境 淫荡 好色 拉后腿 蛀虫 摆弄 半死 名利 发愁 低能 耍赖 侵权 庸才 内疚 蠢货 偏袒 玩弄 凶残 狡猾 喧哗 出风头 抽象 猥亵 逃兵 喧嚣 顾虑 地狱 乌合之众 团伙 腐败 饭桶 强迫 呆子 沉重 逃跑 敷衍 懦弱 掩饰 内乱 寒冷 私藏 迟到 侵犯 拖拉 奸诈 自诩 无精打采 半途而废 上钩 树敌 流弊 肤浅 上台 噪音 窥探 怪物 西风 打斗 骂街 活宝 说谎 装傻 推翻 手法 后人 耗费 骚动 惨败 严酷 虚荣 糊涂 盗版 虎头蛇尾 搅和 小丑 犯罪 扬言 丢失 诋毁 叛逃 忽视 损人利己 冒充 哗众取宠 惨淡 妖孽 内情 冤枉 违规 低落 忧伤 居心 不当 盲目 过度 抢夺 触礁 牢骚 取得 粗鄙 迁就 粗鲁 急躁 上当 卑鄙 毁坏 缺德 笼络 要命 不孝 昏迷 沉闷 残暴 退化 刺儿头 篡位 妨碍 记仇 滑头 招风 作践 烦躁 唾弃 糊弄 愧疚 闹腾 装模作样 保守 羞愧 内奸 奸商 计谋 二流子 瞎闹 独断 惰性 鼓捣 糟蹋 纠纷 怨天尤人 圆滑 刺眼 隔阂 短暂 疙瘩 表功 势利 苦命 野性 狂人 辛酸 明哲保身 乱套 挑三拣四 灭亡 娇惯 怨言 矮子 窝囊 落后 斤斤计较 荒废 阴影 碍眼 恼火 蒙蔽 汉奸 小辫子 辫子 犯人 死板 捧场 畜生 空洞 血腥 盗墓 撒谎 噩梦 苦难 见鬼 抑郁 糟糕 劫持 圈套 发狂 阴森 败笔 颓废 饥荒 嘈杂 威力 挫折 摧残 单薄 浅薄 闲言碎语 没落 压迫 鄙人 恶人 任意 挑剔 下贱 凶手 迷信 虚构 难看 干扰 厌烦 强词夺理 践踏 苦恼 试图 屠杀 相提并论 欺诈 漠视 强求 杀戮 杀害 狗屁 罪过 杂乱 强加 失事 放肆 违反 闹剧 杀气 叛徒 奸细 软弱 胆小 惨烈 辱没 粗糙 造谣 含糊 大肆 搪塞 焦虑 一窝蜂 冷箭 散布 透顶 赌博 偷窃 蠢蠢欲动 傲慢 逃避 扑腾 纷争 短处 强硬 贪图 离间 头子 落伍 谩骂 隐患 徒劳 敌对 不济 尔虞我诈 哀求 费事 悲观 奴役 高傲 匮乏 头目 光棍 暗礁 贼心 失宠 气焰 倒台 南辕北辙 消沉 血淋淋 目光短浅 自食其果 多此一举 受气 扯皮 海盗 凡人 光亮 狭隘 恶毒 当道 白费 反目 浑浊 变心 同流合污 呆傻 呆滞 残杀 堕落 畸形 充斥 争斗 土匪 大话 夸夸其谈 打搅 懒骨头 刚愎自用 乞讨 惭愧 削弱 古怪 称霸 邪道 拜金 黑心 乱糟糟 心术 狼狈为奸 不祥 隐瞒 枭雄 官腔 添乱 狭小 投降 官僚 丧失 虚弱 吵嘴 贪官 要不得 粗俗 打劫 抽风 大言不惭 人云亦云 折本 非议 自夸 论调 苦头 明目张胆 痴呆 不配 一言堂 晦气 扼杀 光火 虚度 言不由衷 贪婪 耽搁 棘手 目空一切 瓦解 反攻 预谋 马虎 小报告 烦心 野蛮 责怪 病夫 作恶多端 遗弃 忌妒 窘迫 油嘴 拙劣 空虚 汗颜 诱饵 玷污 霸权 妒忌 沮丧 黑道 死记 消磨 延误 鬼混 邋遢 狰狞 想入非非 下流 扯后腿 没羞 失职 同床异梦 色狼 早衰 威势 萧然 烟鬼 焦躁 独霸 伤神 糟粕 摇摆 规章制度 胡扯 变天 挫败 蛆虫 把持 贿赂 黑手 糟糠 闹鬼 惊吓 崽子 斗气 厉鬼 幽灵 埋没 歪曲 惆怅 发疯 破败 飘零 张牙舞爪 蓄谋 长夜 窘境 周折 渣滓 荒凉 蛇蝎 腐朽 私货 愚昧 胡乱 失策 拐卖 黑金 盗贼 溺爱 屈服 缺失 偷生 陋习 牵强 忘本 娼妇 谬论 自居 火坑 盗窃 疑虑 杀气腾腾 吸毒 潜逃 沦丧 抓瞎 昏庸 避重就轻 骚扰 衰败 叫嚣 偏颇 丑角 病态 不堪一击 轻狂 亵渎 走狗 斥责 涉嫌 挑动 狂暴 夺取 每况愈下 危害 风骚 暴政 覆灭 暴民 穷凶极恶 绑匪 草芥 泛滥 海难 酷刑 罪孽 束缚 破绽 割让 纳粹 谋杀 仇人 拔高 质问 俗套 杂种 妖魔 挖苦 反抗 幌子 搅乱 压制 草鸡 曲解 煽动 占据 昙花一现 遇难 斗嘴 歇斯底里 骗术 受挫 毛子 亏待 画蛇添足 蠢事 泄露 僵硬 错乱 失利 入魔 扣帽子 蹉跎 擅自 花心 集团 苍白 鬼鬼祟祟 彻头彻尾 撒野 沦陷 嘲笑 敌特 企图 受罚 责问 体罚 禁闭 翻天 逃学 遇险 嬉皮笑脸 编造 嘲讽 垄断 不幸 骗局 狂躁 乌烟瘴气 万恶 肆无忌惮 伤疤 赔钱 灰心 毒害 忧愁 狐假虎威 诈骗 成心 阻挠 兽性 走后门 长短 揩油 侵入 浪荡 矫揉造作 憾事 杞人忧天 暗流 不善 恶语 犯法 可憎 事端 附和 非人 颠倒黑白 奉承 作怪 放任 同谋 风浪 蒙骗 过错 躁动 阳奉阴违 各行其是 篡权 假惺惺 愚弄 唾骂 无动于衷 失意 抢占 敛财 颠倒是非 蛮横 松懈 功亏一篑 声讨 甜言蜜语 冗长 通病 哄抬 阻碍 绝路 懊悔 得过且过 别有用心 吹嘘 小气 差点儿 关节 损害 闭塞 肥胖 迎合 落空 翻脸 操纵 胆怯 迟疑 坎坷 麻木 尖酸 无所作为 赘述 栽赃 花招 货色 白搭 重现 寒心 骂名 训斥 浮华 微小 傲气 反派 致使 死党 孤僻 害群之马 祸水 内讧 滥竽充数 视而不见 漠不关心 退步 忧患 繁杂 惨痛 招牌 山穷水尽 讨价还价 鱼肉 野心勃勃 拘谨 八面玲珑 本末倒置 叛卖 过激 狂妄自大 反面 想方设法 坏处 丑陋 专权 牟利 逼迫 冰冷 泡汤 鼓动 拖沓 瘦弱 残货 阴冷 投机 出格 弊病 故障 褒贬 毒品 违法 插手 糜烂 装腔作势 一味 触犯 灾害 犯愁 复古 牢笼 毒素 肮脏 浓艳 罪恶 窥视 犯规 公主 老鼠 逃走 富二代 公子哥 磨洋工 化妆 退出 娇贵 奇葩 装 无聊 农村生活 删帖 声音 切镜头 卸载 底线 删了 停播 整顿 猫腻 脑残剧 不看 秀 剧本 没意思 假 不真实 )
  #我们15个人物关键词
  KWS = {
    "肖凡凡" => %w(肖凡凡 云南妹 黑妹 洗头妹 骚浪贱 学生妹),
    "刘洛汐" => %w(刘落夕 心机婊 心机妹 汐哥 平胸妹 心机表),
    "刘希"   => %w(刘希 刘西 刘熙),
    "聂江伟" => %w(聂江伟 老鬼 队长),
    "张婷媗" => %w(张婷媗 台湾 辣妈 台妹),
    "邓碧莹" => %w(邓碧莹 短发女 广东妹),
    "孙铭"   => %w(孙铭 兵哥),
    "郭道辉" => %w(郭道辉 农民工),
    "刘志轩" => %w(刘志轩 蘑菇头 锅盖头 黑衣男 小四眼 小黑哥 马桶),
    "易秋"  => %w(易秋 道士 易大师 易狗),
    "宋鸽"  => %w(宋鸽 鸽子 博士 哈佛女),
    "丘子建" => %w(丘子建 渣男 拳手),
    "谭丽敏" => %w(谭丽敏 老太太 老太婆 上海阿姨 老奶奶 老阿姨 谭阿姨),
    "郑虎"  => %w(郑虎 胖子 胖胖),
    "刘富华" => %w(刘富华 鲁迅 老刘),
    "韦泽华" => %w(韦泽华 小宝 韦爵爷 韦哥 小韦),
    "陈宪一" => %w(陈宪一)
  }
  # 真正男子汉人物关键词
  KWS1 = {
    "张丰毅" => %w(张丰毅),
    "郭晓冬" => %w(郭晓冬),
    "王宝强" => %w(王宝强),
    "袁弘" => %w(袁弘),
    "刘昊然" => %w(刘昊然),
    "杜海涛" => %w(杜海涛),
    "欧豪" => %w(欧豪),
    "王金武" => %w(王金武),
    "姜伟" => %w(姜伟),
    "闫钊" => %w(闫钊),
    "徐晓东" => %w(徐晓东),
    "王予曦" => %w(王予曦),
    "孙文泽" => %w(孙文泽),
    "文海地" => %w(文海地),
    "谢添" => %w(谢添),
    "班长" => %w(班长),
    "指导员" => %w(指导员),
    "杨根思" => %w(杨根思),
    "马蓉"  => %w(王子豪) 
  }
  # 奇葩说人物关键词
  KWS2 = {
    "马东" => %w(马东),
    "高晓松" => %w(高晓松),
    "蔡康永" => %w(蔡康永),
    "谢依霖" => %w(谢依霖),
    "陶晶莹" => %w(陶晶莹),
    "贾玲" => %w(贾玲),
    "袁姗姗" => %w(袁姗姗),
    "李湘" => %w(李湘),
    "牟頔" => %w(牟頔),
    "马薇薇" => %w(马薇薇),
    "颜如晶" => %w(颜如晶),
    "范湉湉" => %w(范湉湉),
    "肖骁" => %w(肖骁),
    "姜思达" => %w(姜思达),
    "艾力" => %w(艾力),
    "包江浩" => %w(包江浩),
    "魏铭" => %w(魏铭),
    "花希" => %w(花希),
    "饼干" => %w(饼干),
    "纪泽希" => %w(纪泽希),
    "金宇轩" => %w(金宇轩),
    "颜如晶" => %w(颜如晶),
    "刘煊赫" => %w(刘煊赫),
    "刘媛媛" => %w(刘媛媛),
    "章扬" => %w(章扬)    
  }

  # field :title, type: String
  # field :url, type: String
  # field :site, type: String
  # field :keyword,type:String
  # field :start_date,type:String
  # field :end_date,type:String
  # field :type,type:String,default:'video'
  # field :status, type: Integer,default:ENABLE


  # ================ batch 任务相关 start ===================
  # 抓取要监测的节目的贴吧历史数据
  def self.runing_tieba_history_data_tasks(spn,hash)
    #hash = {name:"爸爸去哪2",link:"http://tieba.baidu.com/f?kw=%E7%88%B8%E7%88%B8%E5%8E%BB%E5%93%AA%E5%84%BF&ie=utf-8&pn=0",max_pn:80000}
    max_pn    = hash[:max_pn]
    threads   = []
    (spn..max_pn).each_slice(10) do |pn_arr|
      threads << Thread.new {
        spn   = pn_arr.first 
        epn   = pn_arr.last 
        name  = hash[:name]
        link  = hash[:link].gsub(/pn=0/,"pn=#{spn}")
        limit = epn 
        tieba = MovieSpider::Tieba.new(name,link,Rails.root.to_s + '/cookies.txt',limit)
        res   = tieba.start_crawl
        TiebaTheme.save_history_data(name,res)
      }
    end
    threads.each { |thr| thr.join }
  end

  # 抓取要监测的节目的饭团历史数据
  def self.runing_fantuan_history_data_tasks
    runing_fifteen_fantuan_tasks
  end


  # 贴吧日监测任务
  # max_pn 表示最大的pn值
  # pn值越大表示要抓取的帖子数越多
  # 默认值为3000,即抓取最靠前的 3000个帖子
  def self.runing_tieba_day_tasks(max_pn=3000)
    runing_tieba_tasks(max_pn)
    from = to = Date.today.strftime('%F')
    import_tieba_reports(from,to)
  end

  # 饭团日监测任务
  def self.runing_fantuan_day_tasks(max_page=99)
    runing_fifteen_fantuan_tasks(max_page) #从0开是到99 共100页 2400条帖子
    from = to = Date.today.strftime('%F')
    import_fantuan_reports('我们15个',from,to)
  end

  # ================ batch 任务相关 end   ===================



  # ================ 执行函数相关  start   ===================

  # 贴吧抓取执行函数
  def self.runing_tieba_tasks(max_pn=nil)
    threads   = []
    TIEBA_HASH.each do |name,hash|
      threads << Thread.new {
        link  = hash[:link]
        limit = max_pn.present? ? max_pn : hash[:limit]
        tieba = MovieSpider::Tieba.new(name,link,Rails.root.to_s + '/cookies.txt',limit)
        res   = tieba.start_crawl
        TiebaInfo.save_history_data(name,res)
      }    
    end
    threads.each { |thr| thr.join }
  end

  # 《我们十五个》饭团爬虫任务
  def self.runing_fifteen_fantuan_tasks(limit=nil)
    fantuan  = MovieSpider::Fantuan.new(limit)
    results  = fantuan.start_crawl
    results.each do |result|
      fantuan = Fantuan.where(postid:result['postid']).first
      if fantuan.present?
        fantuan.update_attributes(result)
      else
        Fantuan.create(result)
      end
    end
    # 导出原始数据excel
    #generate_fantuan_original_data_excel(results,from,to)
    #导出统计数据excel
    #generate_fantuan_fifteen_statistics_data_excel
    #导出云词数据excel
    #generate_fantuan_cloud_words_excel
  end

  # ================ 执行函数相关  end     ===================


  # ================ 导出贴吧报表相关 start ===================
  # 批量导出报表
  def self.stuff_import_tieba_reports(hash)
    # hash = {
    #   "我们15个" => {from:'2015-07-15',to:'2015-07-21'},
    #   "真正男子汉" => {from:'2015-05-26',to:'2015-06-01'},
    #   "奇葩说" => {from:'2014-12-24',to:'2014-12-30'},
    #   "爱上超模" => {from:'2015-04-15',to:'2014-04-21'},
    #   "你正常吗" => {from:'2014-05-05',to:'2015-05-11'},
    #   "百万粉丝" => {from:'2014-12-23',to:'2014-12-29'},
    #   "牵手爱情村" => {from:'2015-02-21',to:'2015-02-27'},
    #   "爸爸去哪2" => {from:'2015-02-21',to:'2015-02-27'}
    # }
    threads = []
    hash.each do |name,val|
      threads << Thread.new {
        Task.import_tieba_reports(val[:from],val[:to],name)
      }
    end
    threads.each { |thr| thr.join }    
  end

  # 导出贴吧报表
  def self.import_tieba_reports(from,to,name=nil)
    unless name.present? 
      TIEBA_HASH.each do |name,hash|
        generate_tieba_reports(name,from,to)    
      end    
    else
      generate_tieba_reports(name,from,to)  
    end
  end  

  def self.generate_tieba_reports(name,from,to)
    people_kwds = entangle_kws = warn_kwds = program_kwds = story_kwds = disport_kwds = feature_kwds = nil
    people_kwds,entangle_kws,warn_kwds,program_kwds,story_kwds,disport_kwds,feature_kwds = get_key_words(name)
    generate_tieba_keyword_excel(name,from,to,people_kwds,entangle_kws,warn_kwds,program_kwds,story_kwds,disport_kwds,feature_kwds)
    generate_tieba_people_excel(name,from,to,people_kwds)
    generate_tieba_increment_excel(name,from,to)   
  end




  # 导出贴吧关键词数据 以发帖时间作为提取依据
  def self.generate_tieba_keyword_excel(name,from,to,people_kwds=nil,entangle_kws=nil,warn_kwds=nil,program_kwds=nil,story_kwds=nil,disport_kwds=nil,feature_kwds=nil)
    book   = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "#{name}数据"
    sheet1.row(0).concat %w(节目名称  发帖时间  人物关键词  卷入关键词  预警关键词  节目关键词  剧情关键词  娱乐关键词  人物特征关键词  主题标题  主题内容  正负判断 回帖量) 
    row_count = 0
    TiebaInfo.where(name:name).no_timeout.each do |t|
      begin
        if t.basic['date'].present?
          date   = t.basic['date'].split(' ').first
          if date >= from && date <= to
            title  = t.basic['title']
            cont   = t.basic['content']
            reply  = t.basic['reply']
            people = '' # 人物关键词
            if people_kwds
              people_kwds.each do |name,arr|
                kwd_str = []
                arr.each do |kwd|
                  if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                    kwd_str << kwd
                  end
                end
                if kwd_str.length > 0
                  people += "#{name}=>(#{kwd_str.join(';')})  "
                end
              end
            end
            entangle = '' # 卷入关键词
            if entangle_kws
              entangle_kws.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  entangle += "  #{kwd}"
                end
              end
            end
            warn = '' #预警关键词
            if warn_kwds
              warn_kwds.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  warn += "  #{kwd}"
                end
              end        
            end
            program = '' #节目关键词
            if program_kwds
              program_kwds.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  program += "  #{kwd}"
                end
              end         
            end
            story = '' # 剧情关键词
            if story_kwds
              story_kwds.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  story += "  #{kwd}"
                end
              end          
            end
            disport = '' #娱乐关键词
            if disport_kwds
              disport_kwds.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  disport += "  #{kwd}"
                end
              end          
            end
            feature = ''
            if feature_kwds
              feature_kwds.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  feature += "  #{kwd}"
                end
              end           
            end
    
            begin
              judge_value = get_value(cont)
            rescue
              judge_value = 0.0
            end
            rw = [t.name,date,people,entangle,warn,program,story,disport,feature,title,cont,judge_value,reply.to_i]
            sheet1.row(row_count + 1).replace(rw)
            row_count += 1         
          end        
        end
      rescue
        puts "error:#{$!} at:#{$@}"
        puts '=============================================================================='
      end
    end
    book.write Rails.root.to_s + '/public/export/' + "贴吧_#{name}_关键词数据_#{from}_#{to}.xls"
  end

  # 导出贴吧人物统计数据
  def self.generate_tieba_people_excel(name,from,to,people_kwds=nil)
    if people_kwds
      book   = Spreadsheet::Workbook.new  
      sheet1 = book.create_worksheet :name => "#{name}数据"
      sheet1.row(0).concat %w(日期  人物名称  主题量  回帖量 评论量)
      row_count = 0
      themes = [] # 盛放主题
      posts  = [] # 盛放回帖
      cmts   = [] # 盛放评论
      TiebaInfo.where(name:name).no_timeout.each do |t|
        title  = t.basic['title'].to_s
        cont   = t.basic['content'].to_s     
        people_kwds.each do |name,kws|
          kws.each do |kw|
            if title.match(/#{kw}/) || cont.match(/#{kw}/)
              if t.basic['date']
                themes << {date:t.basic['date'].split(' ').first,name:name}
              end
            end
            if t.posts.length > 0 
              t.posts.each do |post|
                if post['content'].match(/#{kw}/)
                  if post['date']
                    posts << {date:post['date'].split(' ').first,name:name}
                  end
                end
                comments = post['comments']
                if comments && comments.length > 0 
                  comments.each do |cmt|
                    if cmt['content'].match(/#{kw}/)
                      if cmt['date']
                        cmts << {date:cmt['date'].split(' ').first,name:name}
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      from    = Date.parse(from)      
      to      = Date.parse(to)
      results = {}
      from.upto(to) do |date|
        people_kwds.each do |name,kws|
          theme_count = themes.select{|theme| theme[:date] == date.strftime('%F') && theme[:name] == name}.length
          post_count  = posts.select{|post| post[:date] == date.strftime('%F') && post[:name] == name}.length
          cmt_count   = cmts.select{|cmt| cmt[:date] == date.strftime('%F') && cmt[:name] == name}.length
          results["#{date}_#{name}"] = {theme_count:theme_count,post_count:post_count,cmt_count:cmt_count}
        end
      end

      results.each do |key,value|
        dat = key.split('_').first 
        nam = key.split('_').last
        rw = [dat,nam,value[:theme_count],value[:post_count],value[:cmt_count]]
        sheet1.row(row_count + 1).replace(rw)
        row_count += 1        
      end
      book.write Rails.root.to_s + '/public/export/' + "贴吧_#{name}_人物统计_#{from.strftime('%F')}_#{to.strftime('%F')}.xls"
    end
  end

  # 导出贴吧增量计算数据
  def self.generate_tieba_increment_excel(name,from,to)
    book    = Spreadsheet::Workbook.new 
    sheet1  = book.create_worksheet :name => "#{name}数据"
    sheet1.row(0).concat %w(日期  新增主题量  新增回帖量  新增评论量)
    row_count = 0
    theme_result = {}
    post_result  = {} 
    cmt_result   = {}

    TiebaInfo.where(name:name).no_timeout.each do |t|
      basic = t.basic
      posts = t.posts
      if basic['date'] 
        theme_date = basic['date'].split(' ').first
        if theme_date >= from && theme_date <= to 
           if theme_result["#{theme_date}"]
              theme_result["#{theme_date}"] += 1
           else
              theme_result["#{theme_date}"] = 1
           end       
        end
      end
      posts.each do |post|
        if post['date']
          post_date = post['date'].split(' ').first
          if post_date >= from && post_date <= to 
            if post_result["#{post_date}"]
              post_result["#{post_date}"] += 1
            else
              post_result["#{post_date}"] = 1 
            end
          end
        end 
        cmts = post['comments']
        if cmts && cmts.length > 0 
          cmts.each do |cmt|
            if cmt['date']
              cmt_date = cmt['date'].split(' ').first
              if cmt_date >= from && cmt_date <= to 
                if cmt_result["#{cmt_date}"]
                  cmt_result["#{cmt_date}"] += 1
                else
                  cmt_result["#{cmt_date}"] = 1  
                end
              end
            end
          end
        end
      end
    end

    dates = theme_result.keys.concat(post_result.keys).concat(cmt_result.keys).uniq.sort
    dates.each do |date|
      rw = [date,theme_result["#{date}"].to_i,post_result["#{date}"].to_i,cmt_result["#{date}"].to_i]
      sheet1.row(row_count + 1).replace(rw)
      row_count += 1
    end
    book.write Rails.root.to_s + '/public/export/' + "贴吧_#{name}_增量数据_#{from}_#{to}.xls"
  end



  # ================ 导出贴吧报表相关 end   ===================



  # ================ 导出饭团报表相关 start ===================

  def self.import_fantuan_reports(name,from,to)
    people_kwds = entangle_kws = warn_kwds = program_kwds = story_kwds = disport_kwds = feature_kwds = nil
    people_kwds,entangle_kws,warn_kwds,program_kwds,story_kwds,disport_kwds,feature_kwds = get_key_words(name)
    generate_fantuan_keyword_excel(name,from,to,people_kwds,entangle_kws,warn_kwds,program_kwds,story_kwds,disport_kwds,feature_kwds)
    generate_fantuan_people_excel(name,from,to,people_kwds)
    generate_fantuan_increment_excel(name,from,to)      
  end

  def self.generate_fantuan_keyword_excel(name,from,to,people_kwds,entangle_kws,warn_kwds,program_kwds,story_kwds,disport_kwds,feature_kwds)  
    book   = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "#{name}数据"
    sheet1.row(0).concat %w(节目名称  发帖时间  人物关键词  卷入关键词  预警关键词  节目关键词  剧情关键词  娱乐关键词  人物特征关键词  主题标题  主题内容  正负判断 回帖量) 
    row_count = 0 
    Fantuan.all.no_timeout.each do |post|
      begin
        if post.time.present?
          date   = post.time.strftime('%F')
          if date >= from && date <= to
            title  = post.title
            cont   = post.content
            reply  = post.orireplynum
            people = '' # 人物关键词
            if people_kwds
              people_kwds.each do |name,arr|
                kwd_str = []
                arr.each do |kwd|
                  if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                    kwd_str << kwd
                  end
                end
                if kwd_str.length > 0
                  people += "#{name}=>(#{kwd_str.join(';')})  "
                end
              end
            end
            entangle = '' # 卷入关键词
            if entangle_kws
              entangle_kws.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  entangle += "  #{kwd}"
                end
              end
            end
            warn = '' #预警关键词
            if warn_kwds
              warn_kwds.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  warn += "  #{kwd}"
                end
              end        
            end
            program = '' #节目关键词
            if program_kwds
              program_kwds.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  program += "  #{kwd}"
                end
              end         
            end
            story = '' # 剧情关键词
            if story_kwds
              story_kwds.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  story += "  #{kwd}"
                end
              end          
            end
            disport = '' #娱乐关键词
            if disport_kwds
              disport_kwds.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  disport += "  #{kwd}"
                end
              end          
            end
            feature = ''
            if feature_kwds
              feature_kwds.each do |kwd|
                if title.to_s.match(/#{kwd}/) || cont.to_s.match(/#{kwd}/)
                  feature += "  #{kwd}"
                end
              end           
            end
    
            begin
              judge_value = get_value(cont)
            rescue
              judge_value = 0.0
            end
            rw = [t.name,date,people,entangle,warn,program,story,disport,feature,title,cont,judge_value,reply.to_i]
            sheet1.row(row_count + 1).replace(rw)
            row_count += 1         
          end        
        end
      rescue
        puts "error:#{$!} at:#{$@}"
        puts '=============================================================================='
      end      
    end
    book.write Rails.root.to_s + '/public/export/' + "饭团_#{name}_关键词数据_#{from}_#{to}.xls"   
  end

  def self.generate_fantuan_people_excel(name,from,to,people_kwds)
    if people_kwds
      book   = Spreadsheet::Workbook.new  
      sheet1 = book.create_worksheet :name => "#{name}数据"
      sheet1.row(0).concat %w(日期  人物名称 回帖子量 评论量)
      row_count = 0
      themes = [] # 盛放主题
      posts  = [] # 盛放回帖
      Fantuan.all.no_timeout.each do |post|
        title  = post.title.to_s
        cont   = post.content.to_s
        people_kwds.each do |name,kws|
          kws.each do |kw|
            if title.match(/#{kw}/) || cont.match(/#{kw}/)
              if post.time
                themes << {date:post.time.strftime('%F'),name:name}
              end
            end
            if post.comments.length > 0 
              post.comments.each do |cmt|
                cont = cmt['content'].to_s
                if cont.match(/#{kw}/)
                  posts << {date:cmt.time.strftime('%F'),name:name}
                end
              end
            end
          end
        end
      end
      from    = Date.parse(from)      
      to      = Date.parse(to)
      results = {}
      from.upto(to) do |date|
        people_kwds.each do |name,kws|
          theme_count = themes.select{|theme| theme[:date] == date.strftime('%F') && theme[:name] == name}.length
          post_count  = posts.select{|post| post[:date] == date.strftime('%F') && post[:name] == name}.length
          results["#{date}_#{name}"] = {theme_count:theme_count,post_count:post_count}
        end
      end

      results.each do |key,value|
        dat = key.split('_').first 
        nam = key.split('_').last
        rw = [dat,nam,value[:theme_count],value[:post_count]]
        sheet1.row(row_count + 1).replace(rw)
        row_count += 1        
      end
      book.write Rails.root.to_s + '/public/export/' + "饭团_#{name}_人物统计_#{from.strftime('%F')}_#{to.strftime('%F')}.xls"
    end    
  end

  def self.generate_fantuan_increment_excel(name,from,to)
    book    = Spreadsheet::Workbook.new 
    sheet1  = book.create_worksheet :name => "#{name}数据"
    sheet1.row(0).concat %w(日期  新增主题量  新增评论量)
    row_count = 0
    theme_result = {}
    post_result  = {}

    Fantuan.all.no_timeout.each do |post|

      if post.time
        theme_date = post.time.strftime('%F')
        if theme_date >= from && theme_date <= to 
           if theme_result["#{theme_date}"]
              theme_result["#{theme_date}"] += 1
           else
              theme_result["#{theme_date}"] = 1
           end       
        end
      end

      if comments.length > 0 
        comments.each do |cmt|
          cmt_date = cmt.time.strftime('%F')
          if cmt_date >= from && cmt_date <= to 
            if post_result["#{cmt_date}"]
              post_result["#{cmt_date}"] += 1
            else
              post_result["#{cmt_date}"]  = 1
            end
          end
        end
      end
    end

    dates = theme_result.keys.concat(post_result.keys).uniq.sort
    dates.each do |date|
      rw = [date,theme_result["#{date}"].to_i,post_result["#{date}"].to_i]
      sheet1.row(row_count + 1).replace(rw)
      row_count += 1
    end
    book.write Rails.root.to_s + '/public/export/' + "饭团_#{name}_增量数据_#{from}_#{to}.xls"    
  end


  # ================ 导出饭团报表相关 end   ===================


  # ================ 公用函数部分相关 start ===================
  def self.get_key_words(name)
    case name 
    when '我们15个'
      #人物关键词  卷入关键词 预警关键词 节目关键词 剧情关键词 娱乐关键词 人物特征关键词
      [KWS,ENTANGLE1,WARN1,PROGRAM,STORY,DISPORT,FEATURE]
    when '真正男子汉'
      [KWS1,ENTANGLE2,WARN2]
    when '奇葩说'
      [KWS2,ENTANGLE3,WARN3]
    when '爸爸去哪2'
    when '爱上超模'
    when '你正常吗'
    when '百万粉丝'
    when '牵手爱情村'
    end
  end

  def self.get_value(word)
    params = {poc:'s',texts:word}
    uri = URI.parse('http://staging.wenjuanba.com:4567/api/sent')
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(params)
    response = http.request(request)
    body = JSON.parse(response.body)
    return body['texts'][0][1]
  end  
  # ================ 公用函数部分相关 start ===================


  #================= 弹幕相关 start =========================
  #《我们十五个》腾讯视频直播弹幕任务
  def self.runing_fifteen_qqlive_tasks
    qqlive  = MovieSpider::Qqlive.new
    results = qqlive.start_crawl
    results.each do |result|
      qlive = Qqlive.where(cmt_id:result[:cmt_id]).first
      unless qlive.present?
        Qqlive.create(result)
      else
        Rails.logger.info '已经存在。。。。。。。。。。。。'
      end
    end
  end

  # 导出 我们15个 腾讯视频直播 相关数据
  def self.export_qqlive_datas_excel(td)
    if td
      td   = Date.parse(td)
    else
      td   = Date.today
    end
    datas  = Qqlive.where(:created_at.gte => td,:created_at.lt => td + 1.days).to_a
    export_qqlive_original_excel(td,datas)
    export_qqlive_statistics_data_excel(td,datas)
    export_qqlive_cloud_words(td,datas)
  end

  # 导出 我们15个 腾讯视频直播原始数据
  def self.export_qqlive_original_excel(td,datas)
    book      = Spreadsheet::Workbook.new
    sheet1    = book.create_worksheet :name => '弹幕原始数据'
    row_count = 0
    sheet1.row(0).concat %w(时间 评论人  点赞数  内容)
    row_count = 0
    datas.each do |data|
      rw = [data.time.strftime('%Y-%m-%d %H:%I:%S'), data.nick,data.up.to_i,data.cont]
      sheet1.row(row_count + 1).replace(rw)
      row_count += 1       
    end
    book.write Rails.root.to_s + '/public/export/' + "弹幕_原始数据_#{td.strftime('%F')}.xls"
  end

  # 导出 我们15个 腾讯视频直播统计数据
  def self.export_qqlive_cloud_words(td,datas)
    book      = Spreadsheet::Workbook.new
    sheet1    = book.create_worksheet :name => '弹幕统计数据'
    row_count = 0
    sheet1.row(0).concat %w(云词文本)
    row_count = 0
    datas.each do |data|
      rw = [data.cont]
      sheet1.row(row_count + 1).replace(rw)
      row_count += 1       
    end
    book.write Rails.root.to_s + '/public/export/' + "弹幕_云词数据_#{td.strftime('%F')}.xls"  
  end

  # 导出 我们15个 腾讯视频直播统计数据
  def self.export_qqlive_statistics_data_excel(td,datas)
    book      = Spreadsheet::Workbook.new
    sheet1    = book.create_worksheet :name => '弹幕云词数据'
    row_count = 0
    sheet1.row(0).concat %w(姓名  关键词  频次)
    row_count = 0
    KWS.each do |name,arr|
      arr.each do |kwd|
        count = 0
        datas.each do |data|
          if data.cont.match(/#{kwd}/)
            count += 1
          end
        end
        rw = [name,kwd,count]
        sheet1.row(row_count + 1).replace(rw)
        row_count += 1
      end
    end
    book.write Rails.root.to_s + '/public/export/' + "弹幕_统计数据_#{td.strftime('%F')}.xls"  
  end
  #================= 弹幕相关 start =========================

end
