# 需求文档

## 简介

一款独立的 iOS 图片编辑应用，UI 风格模仿 Adobe Lightroom。用户可以从相册选择照片，进行基础参数调整（曝光、对比度、饱和度等）、裁剪、旋转、滤镜应用等操作，支持撤销/重做，并可导出编辑后的照片。使用 Swift + UIKit 开发，图标使用 SF Symbols。

## 术语表

- **Photo_Editor**: 图片编辑模块的主界面，包含图片预览区域和编辑工具面板
- **Adjustment_Panel**: 调整面板，包含曝光、对比度、高光、阴影、饱和度等滑块控件
- **Filter_Engine**: 滤镜引擎，基于 Core Image，负责将调整参数应用到图片上生成预览和最终输出
- **Crop_Tool**: 裁剪工具，支持自由裁剪和固定比例裁剪
- **Edit_History**: 编辑历史管理器，负责撤销/重做操作的记录和回放
- **Export_Manager**: 导出管理器，负责将编辑后的图片以指定格式和质量导出

## 需求

### 需求 1：图片加载与预览

**用户故事：** 作为用户，我希望将照片加载到编辑器中并看到实时预览，以便在导出前评估我的编辑效果。

#### 验收标准

1. WHEN 用户从相册中选择一张照片, THE Photo_Editor SHALL 在中央预览区域以正确的宽高比显示该照片
2. WHEN 照片正在加载时, THE Photo_Editor SHALL 显示加载指示器直到照片准备就绪
3. IF 选择的照片加载失败, THEN THE Photo_Editor SHALL 显示错误信息并允许用户重试或选择其他照片
4. WHEN 调整参数发生变化, THE Filter_Engine SHALL 在 100ms 内为不超过 1200 万像素的照片生成更新后的预览

### 需求 2：基础调整参数

**用户故事：** 作为用户，我希望通过滑块调整曝光、对比度、饱和度等参数，以便精细调整照片的外观。

#### 验收标准

1. THE Adjustment_Panel SHALL 提供以下参数的滑块：曝光、对比度、高光、阴影、饱和度、自然饱和度、色温、锐度
2. WHEN 用户移动滑块, THE Adjustment_Panel SHALL 在滑块旁显示当前数值
3. WHEN 用户移动滑块, THE Filter_Engine SHALL 实时将对应的调整应用到预览图上
4. THE Adjustment_Panel SHALL 允许每个滑块的范围为 -100 到 +100，默认值为 0
5. WHEN 用户双击滑块, THE Adjustment_Panel SHALL 将该滑块重置为默认值 0

### 需求 3：滤镜预设

**用户故事：** 作为用户，我希望对照片应用预设滤镜，以便无需手动调整即可快速获得想要的效果。

#### 验收标准

1. THE Photo_Editor SHALL 提供一个水平可滚动的滤镜预设列表，带有缩略图预览
2. WHEN 用户点击一个滤镜预设, THE Filter_Engine SHALL 将该滤镜应用到照片预览上
3. WHEN 滤镜预设被应用后, THE Adjustment_Panel SHALL 更新所有滑块值以反映该滤镜的参数值
4. THE Photo_Editor SHALL 包含至少 10 个内置滤镜预设，涵盖鲜艳、暖色、冷色、黑白、复古等风格
5. WHEN 用户再次点击当前已激活的滤镜预设, THE Filter_Engine SHALL 移除该滤镜并恢复之前的手动调整值

### 需求 4：裁剪与旋转

**用户故事：** 作为用户，我希望裁剪和旋转照片，以便调整构图和方向。

#### 验收标准

1. WHEN 用户进入裁剪模式, THE Crop_Tool SHALL 在照片上显示一个可调整大小的裁剪框
2. THE Crop_Tool SHALL 支持以下预设宽高比：自由、1:1、4:3、3:2、16:9
3. WHEN 用户选择一个预设宽高比, THE Crop_Tool SHALL 将裁剪框约束为该比例
4. WHEN 用户点击旋转按钮, THE Crop_Tool SHALL 将照片顺时针旋转 90 度
5. WHEN 用户确认裁剪, THE Filter_Engine SHALL 将裁剪应用到照片并更新预览
6. IF 用户取消裁剪操作, THEN THE Crop_Tool SHALL 丢弃所有裁剪和旋转更改并恢复之前的状态

### 需求 5：撤销与重做

**用户故事：** 作为用户，我希望撤销和重做编辑操作，以便自由尝试而不担心丢失之前的状态。

#### 验收标准

1. WHEN 用户执行一次编辑操作, THE Edit_History SHALL 将该操作记录为一条新的历史条目
2. WHEN 用户点击撤销按钮, THE Edit_History SHALL 将照片恢复到上一个状态
3. WHEN 用户点击重做按钮, THE Edit_History SHALL 恢复最近一次被撤销的状态
4. WHILE 没有执行过任何编辑操作, THE Photo_Editor SHALL 禁用撤销按钮
5. WHILE 没有被撤销的操作, THE Photo_Editor SHALL 禁用重做按钮
6. WHEN 用户在撤销后执行新的编辑操作, THE Edit_History SHALL 丢弃当前状态之后的所有重做历史

### 需求 6：导出

**用户故事：** 作为用户，我希望以高质量导出编辑后的照片，以便保存或分享结果。

#### 验收标准

1. WHEN 用户点击导出按钮, THE Export_Manager SHALL 渲染应用了所有调整的全分辨率编辑照片
2. THE Export_Manager SHALL 支持 JPEG 和 PNG 格式导出
3. WHEN 以 JPEG 格式导出时, THE Export_Manager SHALL 允许用户选择 1 到 100 的质量值，默认为 90
4. WHEN 导出正在进行中, THE Photo_Editor SHALL 显示进度指示器
5. WHEN 导出成功完成, THE Export_Manager SHALL 将照片保存到用户的相册并显示成功确认
6. IF 导出失败, THEN THE Export_Manager SHALL 显示包含失败原因的错误信息

### 需求 7：Lightroom 风格 UI

**用户故事：** 作为用户，我希望拥有类似 Lightroom 的深色主题编辑界面，以便专注于照片而不被 UI 干扰。

#### 验收标准

1. THE Photo_Editor SHALL 使用深色主题，近黑色背景（#1A1A1A）和浅色文字（#E0E0E0）
2. THE Photo_Editor SHALL 在屏幕上方显示照片预览，下方显示编辑工具
3. THE Adjustment_Panel SHALL 将编辑工具组织为标签组：光效、颜色、效果、细节
4. THE Photo_Editor SHALL 所有工具图标使用 SF Symbols
5. WHEN 切换工具标签时, THE Adjustment_Panel SHALL 以平滑的水平滑动动画过渡

### 需求 8：编辑参数序列化

**用户故事：** 作为开发者，我希望序列化和反序列化编辑参数，以便编辑状态可以被保存和恢复。

#### 验收标准

1. THE Filter_Engine SHALL 将所有当前编辑参数序列化为 JSON 表示
2. WHEN 提供有效的 JSON 编辑参数字符串, THE Filter_Engine SHALL 将其反序列化为等效的编辑参数集
3. FOR ALL 有效的编辑参数集，序列化后再反序列化 SHALL 产生等效的参数集（round-trip 属性）
4. THE Filter_Engine SHALL 使用 Pretty_Printer 格式化编辑参数 JSON 以生成人类可读的输出
