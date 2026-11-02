#!/usr/bin/env python3
"""Builds App/Sources/Resources/Localizable.xcstrings (en, zh-Hans, zh-Hant).
Simplified is written by hand below; Traditional is derived with OpenCC (pip install opencc-python-reimplemented).
Run after adding UI strings, then have a native speaker review the Chinese before release."""
import json, pathlib
import opencc

S = {  # English key -> Simplified Chinese
 "Inbox": "收件箱", "Settings": "设置", "Done": "完成", "Search thoughts": "搜索想法", "New thought": "新想法",
 "Undo": "撤销", "Pinned": "已置顶", "Pin": "置顶", "Unpin": "取消置顶", "Archive": "归档", "Archived": "已归档",
 "Restore": "恢复", "Share": "分享", "Copy": "拷贝", "Delete": "删除", "Deleted": "已删除", "Cancel": "取消", "Save": "保存",
 "Press the Action Button and say what's on your mind.": "按下操作按钮，说出你的想法。",
 "Turn on on-device AI": "开启设备端 AI", "Downloading on-device AI": "正在下载设备端 AI", "Download": "下载", "Retry": "重试",
 "You can keep capturing thoughts while this downloads.": "下载期间你仍可以继续记录想法。",
 "Download %@ (%@) to structure thoughts without the internet.": "下载 %@（%@），无需联网即可整理想法。",
 "Type instead": "改为输入", "Stop": "停止", "Recording": "正在录音", "Double tap to stop and save": "双击以停止并保存",
 "Live transcript": "实时转写", "Type a thought": "输入想法", "Open Settings": "打开设置",
 "Microphone or speech access is off. You can still type a thought, or turn access on in Settings.": "麦克风或语音权限已关闭。你仍可以输入想法，或在设置中开启权限。",
 "Empty thought": "空白想法", "Structuring…": "正在整理…", "Couldn't structure": "无法整理",
 "Raw": "原文", "Structured": "已整理", "What you said": "你说的话", "No words were recognised.": "没有识别到文字。",
 "Action items": "待办事项", "Title": "标题", "More": "更多", "Share as Markdown": "以 Markdown 分享", "Share as text": "以文本分享",
 "Structure again": "重新整理", "Replace your edits?": "替换你的修改？", "Replace with new result": "替换为新结果", "Keep my edits": "保留我的修改",
 "You edited this thought. Structuring it again will overwrite the title and text you changed.": "你编辑过这条想法。重新整理会覆盖你修改的标题和文字。",
 "Try again": "再试一次",
 "Saved. It will be structured when an on-device model is available.": "已保存。设备端模型可用时会自动整理。",
 "Couldn't structure this thought. Your words are safe.": "无法整理这条想法，但你的原话已安全保存。",
 "Capture": "录音", "Auto-stop after %@ s of silence": "静音 %@ 秒后自动停止",
 "Speech language": "语音语言", "Follow device": "跟随设备", "English": "English", "中文": "中文",
 "Chinese script": "中文字形", "简体": "简体", "繁體": "繁體",
 "Privacy": "隐私", "Private mode": "隐私模式", "Keep audio": "保留录音", "Don't keep": "不保留",
 "7 days": "7 天", "30 days": "30 天", "90 days": "90 天",
 "Private mode never keeps audio and never uses Enhanced mode. Audio stays on this device.": "隐私模式不保留录音，也不使用增强模式。录音只保存在本机。",
 "On-device AI": "设备端 AI", "Download on Wi-Fi only": "仅在 Wi-Fi 下下载", "Accuracy pass after recording": "录音后精校",
 "Models are downloaded after install and can be deleted here. Capture works while they download.": "模型在安装后下载，可在此删除。下载期间仍可录音。",
 "Cloud": "云端", "Enhanced mode": "增强模式",
 "Off by default. When on, the text of each thought is sent to %@ to structure it. Audio is never sent.": "默认关闭。开启后，每条想法的文字会发送给 %@ 进行整理。录音绝不会上传。",
 "Archived thoughts": "已归档的想法", "Open-source licenses": "开源许可", "Nothing archived": "没有已归档内容",
 "Turn on Enhanced mode?": "开启增强模式？", "What is sent": "发送的内容",
 "The text of each thought you capture (the transcript). Audio is never sent.": "你记录的每条想法的文字（转写内容）。录音绝不会上传。",
 "Who receives it": "接收方", "%@, through our server, which only forwards the text and keeps no copy.": "%@，经由我们的服务器转发，服务器只转发文字、不保留副本。",
 "Why": "原因", "A larger model can structure your thought more accurately than the on-device one.": "更大的模型比设备端模型能更准确地整理你的想法。",
 "You stay in control": "由你掌控", "Turn it off any time in Settings. Nothing is sent until you agree.": "可随时在设置中关闭。在你同意之前不会发送任何内容。",
 "Agree and turn on": "同意并开启", "Not now": "暂不",
}
cc = opencc.OpenCC("s2twp")
out = {"sourceLanguage": "en", "version": "1.0", "strings": {}}
for k, hans in S.items():
    hant = cc.convert(hans)
    out["strings"][k] = {"localizations": {
        "en": {"stringUnit": {"state": "translated", "value": k}},
        "zh-Hans": {"stringUnit": {"state": "translated", "value": hans}},
        "zh-Hant": {"stringUnit": {"state": "translated", "value": hant}},
    }}
path = pathlib.Path(__file__).resolve().parent.parent / "App/Sources/Resources/Localizable.xcstrings"
path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n")
print(f"{len(S)} strings -> {path}")
