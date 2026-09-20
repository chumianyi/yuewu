import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 前端内置本地化字典（不请求后端）。
/// 支持：zh（简体中文，默认）/ en-US / en-GB / fr / ru / zh-TW
class AppLocale {
  AppLocale._internal();
  static final AppLocale instance = AppLocale._internal();

  String _lang = 'zh';
  String get lang => _lang;

  /// 语言变化时通知 UI 重建
  final ValueNotifier<String> langNotifier = ValueNotifier<String>('zh');

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'zh', 'name': '简体中文'},
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'en-GB', 'name': 'English (UK)'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'ru', 'name': 'Русский'},
    {'code': 'zh-TW', 'name': '繁體中文'},
  ];

  static const _prefsKey = 'app_lang';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _lang = p.getString(_prefsKey) ?? 'zh';
    langNotifier.value = _lang;
  }

  Future<void> setLang(String code) async {
    _lang = code;
    langNotifier.value = code;
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, code);
  }

  String languageName(String code) {
    for (final l in supportedLanguages) {
      if (l['code'] == code) return l['name'] ?? code;
    }
    return code;
  }

  // ── UI 文案字典 ──────────────────────────────────────
  static const Map<String, Map<String, String>> _ui = {
    '主页': {'en-US': 'Home', 'en-GB': 'Home', 'fr': 'Accueil', 'ru': 'Главная', 'zh-TW': '主頁'},
    '伙伴': {'en-US': 'Friends', 'en-GB': 'Friends', 'fr': 'Amis', 'ru': 'Друзья', 'zh-TW': '夥伴'},
    '消息': {'en-US': 'Messages', 'en-GB': 'Messages', 'fr': 'Messages', 'ru': 'Сообщения', 'zh-TW': '訊息'},
    '我的': {'en-US': 'Profile', 'en-GB': 'Profile', 'fr': 'Profil', 'ru': 'Профиль', 'zh-TW': '我的'},
    '搜索角色或故事...': {
      'en-US': 'Search characters or stories...',
      'en-GB': 'Search characters or stories...',
      'fr': 'Rechercher personnages ou histoires...',
      'ru': 'Поиск персонажей или историй...',
      'zh-TW': '搜尋角色或故事...'
    },
    '换一批': {'en-US': 'Shuffle', 'en-GB': 'Shuffle', 'fr': 'Changer', 'ru': 'Показать другие', 'zh-TW': '換一批'},
    '搜索': {'en-US': 'Search', 'en-GB': 'Search', 'fr': 'Rechercher', 'ru': 'Поиск', 'zh-TW': '搜尋'},
    '取消': {'en-US': 'Cancel', 'en-GB': 'Cancel', 'fr': 'Annuler', 'ru': 'Отмена', 'zh-TW': '取消'},
    '暂无结果': {'en-US': 'No results', 'en-GB': 'No results', 'fr': 'Aucun résultat', 'ru': 'Ничего не найдено', 'zh-TW': '暫無結果'},
    '角色': {'en-US': 'Characters', 'en-GB': 'Characters', 'fr': 'Personnages', 'ru': 'Персонажи', 'zh-TW': '角色'},
    '故事': {'en-US': 'Stories', 'en-GB': 'Stories', 'fr': 'Histoires', 'ru': 'Истории', 'zh-TW': '故事'},
    '隐私政策': {'en-US': 'Privacy Policy', 'en-GB': 'Privacy Policy', 'fr': 'Politique de confidentialité', 'ru': 'Политика конфиденциальности', 'zh-TW': '隱私權政策'},
    '注销账号': {'en-US': 'Delete Account', 'en-GB': 'Delete Account', 'fr': 'Supprimer le compte', 'ru': 'Удалить аккаунт', 'zh-TW': '刪除帳號'},
    '语言设置': {'en-US': 'Language', 'en-GB': 'Language', 'fr': 'Langue', 'ru': 'Язык', 'zh-TW': '語言設定'},
    '设置': {'en-US': 'Settings', 'en-GB': 'Settings', 'fr': 'Paramètres', 'ru': 'Настройки', 'zh-TW': '設定'},
    '退出登录': {'en-US': 'Log Out', 'en-GB': 'Log Out', 'fr': 'Se déconnecter', 'ru': 'Выйти', 'zh-TW': '登出'},
    '确认注销': {'en-US': 'Confirm Deletion', 'en-GB': 'Confirm Deletion', 'fr': 'Confirmer la suppression', 'ru': 'Подтвердить удаление', 'zh-TW': '確認刪除'},
    '注销后账号将无法登录，对话记录将被删除，发布的内容将被下架。此操作不可恢复。': {
      'en-US': 'After deletion, you cannot log in. Chat history will be removed and your published content taken down. This cannot be undone.',
      'en-GB': 'After deletion, you cannot log in. Chat history will be removed and your published content taken down. This cannot be undone.',
      'fr': 'Après la suppression, vous ne pourrez plus vous connecter. L\'historique sera effacé et vos publications retirées. Action irréversible.',
      'ru': 'После удаления вы не сможете войти. История чата будет удалена, публикации скрыты. Действие необратимо.',
      'zh-TW': '刪除後將無法登入，對話記錄將被刪除，發布內容將被下架。此操作無法復原。'
    },
    '再次确认：输入「注销」以继续': {
      'en-US': 'Type "DELETE" to confirm',
      'en-GB': 'Type "DELETE" to confirm',
      'fr': 'Tapez « SUPPRIMER » pour confirmer',
      'ru': 'Введите « УДАЛИТЬ » для подтверждения',
      'zh-TW': '輸入「刪除」以確認'
    },
    '注销成功': {'en-US': 'Account deleted', 'en-GB': 'Account deleted', 'fr': 'Compte supprimé', 'ru': 'Аккаунт удалён', 'zh-TW': '帳號已刪除'},
    '选择语言': {'en-US': 'Choose Language', 'en-GB': 'Choose Language', 'fr': 'Choisir la langue', 'ru': 'Выберите язык', 'zh-TW': '選擇語言'},
    '加载中...': {'en-US': 'Loading...', 'en-GB': 'Loading...', 'fr': 'Chargement...', 'ru': 'Загрузка...', 'zh-TW': '載入中...'},
    '重试': {'en-US': 'Retry', 'en-GB': 'Retry', 'fr': 'Réessayer', 'ru': 'Повторить', 'zh-TW': '重試'},
    '继续': {'en-US': 'Continue', 'en-GB': 'Continue', 'fr': 'Continuer', 'ru': 'Продолжить', 'zh-TW': '繼續'},
    '已切换': {'en-US': 'Language changed', 'en-GB': 'Language changed', 'fr': 'Langue changée', 'ru': 'Язык изменён', 'zh-TW': '已切換'},
  };

  /// 翻译 UI 文案
  String t(String zh) {
    if (_lang == 'zh' || zh.isEmpty) return zh;
    return _ui[zh]?[_lang] ?? zh;
  }

  // ── 角色名称/描述的简单关键词翻译表 ─────────────────────
  static const Map<String, Map<String, String>> _keywordTable = {
    'en-US': {
      '少女': 'girl', '少年': 'boy', '女孩': 'girl', '男孩': 'boy',
      '温柔': 'gentle', '冷漠': 'cold', '可爱': 'cute', '高冷': 'aloof',
      '傲娇': 'tsundere', '治愈': 'healing', '神秘': 'mysterious',
      '老师': 'teacher', '学生': 'student', '精灵': 'elf', '魔女': 'witch',
      '吸血鬼': 'vampire', '狼人': 'werewolf', '公主': 'princess', '王子': 'prince',
      '女仆': 'maid', '管家': 'butler', '机器人': 'robot', 'AI': 'AI',
      '故事': 'story', '剧情': 'plot', '冒险': 'adventure', '恋爱': 'romance',
      '校园': 'school', '都市': 'urban', '奇幻': 'fantasy', '科幻': 'sci-fi',
      '古风': 'ancient', '仙侠': 'xianxia', '武侠': 'wuxia', '悬疑': 'mystery',
      '对话': 'chat', '聊天': 'chat', '伙伴': 'partner', '朋友': 'friend',
      '你好': 'hello', '世界': 'world', '爱': 'love', '梦': 'dream',
      '星': 'star', '月': 'moon', '花': 'flower', '雪': 'snow', '风': 'wind',
      '光': 'light', '影': 'shadow', '夜': 'night', '日': 'day',
      '我': 'I', '你': 'you', '他': 'he', '她': 'she',
      '是': 'is', '的': ' ', '了': '', '在': 'at', '和': 'and',
    },
    'en-GB': {
      '少女': 'girl', '少年': 'boy', '女孩': 'girl', '男孩': 'boy',
      '温柔': 'gentle', '冷漠': 'cold', '可爱': 'cute', '高冷': 'aloof',
      '傲娇': 'tsundere', '治愈': 'healing', '神秘': 'mysterious',
      '老师': 'teacher', '学生': 'student', '精灵': 'elf', '魔女': 'witch',
      '吸血鬼': 'vampire', '狼人': 'werewolf', '公主': 'princess', '王子': 'prince',
      '女仆': 'maid', '管家': 'butler', '机器人': 'robot',
      '故事': 'story', '剧情': 'plot', '冒险': 'adventure', '恋爱': 'romance',
      '校园': 'school', '都市': 'urban', '奇幻': 'fantasy', '科幻': 'sci-fi',
      '古风': 'ancient', '仙侠': 'xianxia', '武侠': 'wuxia', '悬疑': 'mystery',
      '对话': 'chat', '聊天': 'chat', '伙伴': 'partner', '朋友': 'friend',
      '你好': 'hello', '世界': 'world', '爱': 'love', '梦': 'dream',
      '星': 'star', '月': 'moon', '花': 'flower', '雪': 'snow',
    },
    'fr': {
      '少女': 'jeune fille', '少年': 'garçon', '女孩': 'fille', '男孩': 'garçon',
      '温柔': 'doux', '冷漠': 'froid', '可爱': 'mignon', '高冷': 'distant',
      '神秘': 'mystérieux', '老师': 'professeur', '学生': 'élève',
      '精灵': 'elfe', '魔女': 'sorcière', '公主': 'princesse', '王子': 'prince',
      '故事': 'histoire', '冒险': 'aventure', '恋爱': 'romance',
      '校园': 'école', '奇幻': 'fantastique', '科幻': 'science-fiction',
      '对话': 'discussion', '聊天': 'chat', '伙伴': 'compagnon', '朋友': 'ami',
      '你好': 'bonjour', '世界': 'monde', '爱': 'amour', '梦': 'rêve',
      '星': 'étoile', '月': 'lune', '花': 'fleur', '雪': 'neige',
    },
    'ru': {
      '少女': 'девушка', '少年': 'юноша', '女孩': 'девочка', '男孩': 'мальчик',
      '温柔': 'нежный', '冷漠': 'холодный', '可爱': 'милый', '高冷': 'отстранённый',
      '神秘': 'таинственный', '老师': 'учитель', '学生': 'ученик',
      '精灵': 'эльф', '魔女': 'ведьма', '公主': 'принцесса', '王子': 'принц',
      '故事': 'история', '冒险': 'приключение', '恋爱': 'романтика',
      '校园': 'школа', '奇幻': 'фэнтези', '科幻': 'фантастика',
      '对话': 'диалог', '聊天': 'чат', '伙伴': 'партнёр', '朋友': 'друг',
      '你好': 'привет', '世界': 'мир', '爱': 'любовь', '梦': 'сон',
      '星': 'звезда', '月': 'луна', '花': 'цветок', '雪': 'снег',
    },
    'zh-TW': {
      '视频': '影片', '软件': '軟體', '信息': '資訊', '网络': '網路',
      '创建': '建立', '角色': '角色', '故事': '故事', '设置': '設定',
      '登录': '登入', '注销': '登出', '删除': '刪除', '隐私': '隱私',
      '账号': '帳號', '对话': '對話', '游戏': '遊戲', '文件': '檔案',
      '帮助': '說明', '反馈': '意見回饋', '评论': '評論', '点赞': '按讚',
      '喜欢': '喜歡', '收藏': '收藏', '分享': '分享', '搜索': '搜尋',
      '历史': '歷史', '记录': '記錄', '音乐': '音樂', '图片': '圖片',
      '表情': '表情符號', '视频通话': '視訊通話', '语音': '語音',
    },
  };

  /// 翻译角色名称/描述（关键词替换，尽力而为）
  String translateContent(String? text) {
    if (text == null || text.isEmpty) return '';
    if (_lang == 'zh') return text;
    final table = _keywordTable[_lang];
    if (table == null) return text;
    var result = text;
    table.forEach((zh, tr) {
      result = result.replaceAll(zh, tr);
    });
    return result;
  }
}
