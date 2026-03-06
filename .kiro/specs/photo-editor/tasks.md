# 实现计划：图片编辑器

## 概述

基于 Swift + UIKit + Core Image 实现一个 Lightroom 风格的独立 iOS 图片编辑应用。按照数据模型 → 核心引擎 → 编辑历史 → UI 层 → 导出的顺序逐步实现，每步都有对应的测试验证。

## 任务

- [x] 1. 初始化项目结构
  - 创建新的 Xcode 项目（Single View App，Swift，UIKit）
  - 创建目录结构：Models/、ViewModels/、Views/、Services/、Tests/
  - 配置 Podfile，添加 SwiftCheck 依赖（pod 'SwiftCheck'）
  - 执行 pod install，使用 .xcworkspace 开发
  - 配置 XCTest target
  - _Requirements: 7.1, 7.4_

- [-] 2. 实现数据模型
  - [x] 2.1 实现 EditParameters、AdjustmentKey、ToolTab、AspectRatio、ExportFormat、FilterPreset
    - EditParameters 遵循 Codable 和 Equatable
    - AdjustmentKey 包含 displayName、iconName（SF Symbol）、tabGroup 计算属性
    - ToolTab 包含 light、color、effects、detail 四个 case
    - AspectRatio 包含 free、square、fourThree、threeTwo、sixteenNine
    - _Requirements: 2.1, 2.4, 4.2, 7.3_

  - [ ]* 2.2 编辑参数序列化 round-trip 属性测试
    - **Property 11: 编辑参数序列化 round-trip**
    - **Validates: Requirements 8.1, 8.2, 8.3**

  - [ ]* 2.3 参数范围与默认值不变量属性测试
    - **Property 2: 参数范围与默认值不变量**
    - **Validates: Requirements 2.4, 2.5**

- [-] 3. 实现 EditHistory 服务
  - [x] 3.1 实现 EditHistory 类
    - push/undo/redo 方法
    - canUndo/canRedo 计算属性
    - undo 后 push 新操作清除 redo 栈
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [ ]* 3.2 编辑历史增长不变量属性测试
    - **Property 8: 编辑历史增长不变量**
    - **Validates: Requirements 5.1**

  - [ ]* 3.3 undo-redo round-trip 属性测试
    - **Property 9: undo-redo round-trip**
    - **Validates: Requirements 5.2, 5.3**

  - [ ]* 3.4 新操作清除 redo 历史属性测试
    - **Property 10: 新操作清除 redo 历史**
    - **Validates: Requirements 5.6**

- [ ] 4. 检查点 - 确保所有测试通过
  - 确保所有测试通过，如有问题请询问用户。

- [x] 5. 实现 FilterEngine 服务
  - [x] 5.1 实现 FilterEngine 核心
    - CIContext 初始化
    - apply(parameters:to:) 方法：构建 CIFilter 链（CIExposureAdjust、CIColorControls、CIHighlightShadowAdjust、CITemperatureAndTint、CISharpenLuminance、CIVibrance）
    - 参数值从 -100~+100 映射到各 CIFilter 的实际参数范围
    - generatePreview 方法：降采样 + apply
    - renderFullResolution 方法：全分辨率渲染
    - _Requirements: 1.4, 2.3_

  - [ ]* 5.2 参数调整产生有效输出属性测试
    - **Property 1: 参数调整产生有效输出**
    - **Validates: Requirements 2.3**

  - [x] 5.3 实现裁剪和旋转逻辑
    - 在 apply 方法中处理 cropRect 和 rotationCount
    - 裁剪使用 CIImage.cropped(to:)
    - 旋转使用 CIImage.transformed(by:) 配合 CGAffineTransform
    - _Requirements: 4.4, 4.5_

- [-] 6. 实现 CropViewModel
  - [x] 6.1 实现 CropViewModel
    - cropRect、aspectRatio、rotationCount 属性
    - rotate90Clockwise 方法（rotationCount = (rotationCount + 1) % 4）
    - constrainToAspectRatio 方法
    - reset 方法
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.6_

  - [ ]* 6.2 旋转 round-trip 属性测试
    - **Property 6: 旋转 round-trip**
    - **Validates: Requirements 4.4**

  - [ ]* 6.3 宽高比约束正确性属性测试
    - **Property 5: 宽高比约束正确性**
    - **Validates: Requirements 4.3**

- [-] 7. 实现 PhotoEditorViewModel
  - [x] 7.1 实现 PhotoEditorViewModel
    - 持有 FilterEngine、EditHistory、当前 EditParameters
    - updateParameter/applyFilter/removeFilter/applyCrop/undo/redo 方法
    - onPreviewUpdated/onHistoryChanged 回调
    - 滤镜应用时保存之前的手动参数，取消时恢复
    - _Requirements: 2.3, 2.5, 3.2, 3.3, 3.5, 5.1, 5.2, 5.3, 5.6_

  - [ ]* 7.2 滤镜应用同步参数属性测试
    - **Property 3: 滤镜应用同步参数**
    - **Validates: Requirements 3.2, 3.3**

  - [ ]* 7.3 滤镜应用-取消 round-trip 属性测试
    - **Property 4: 滤镜应用-取消 round-trip**
    - **Validates: Requirements 3.5**

  - [ ]* 7.4 裁剪取消恢复状态属性测试
    - **Property 7: 裁剪取消恢复状态**
    - **Validates: Requirements 4.6**

- [x] 8. 检查点 - 确保所有测试通过
  - 确保所有测试通过，如有问题请询问用户。

- [x] 9. 实现 UI 层 - 主编辑界面
  - [x] 9.1 实现 PhotoEditorViewController
    - 深色主题配置（背景 #1A1A1A，文字 #E0E0E0）
    - 布局：上方 ImagePreviewView，下方编辑工具区
    - 顶部导航栏：返回、undo、redo、导出按钮
    - 绑定 ViewModel 回调更新 UI
    - _Requirements: 7.1, 7.2, 5.4, 5.5_

  - [x] 9.2 实现 ImagePreviewView
    - 基于 UIImageView，支持 aspect fit 显示
    - 接收 UIImage 更新预览
    - _Requirements: 1.1_

  - [x] 9.3 实现 ToolTabBarView
    - 水平排列的标签按钮：光效、颜色、效果、细节
    - SF Symbols 图标
    - 选中状态高亮
    - 切换时通知 delegate
    - _Requirements: 7.3, 7.4, 7.5_

  - [x] 9.4 实现 AdjustmentPanelView
    - 根据当前 ToolTab 显示对应的滑块列表
    - 每个滑块显示参数名、图标、当前值、滑块控件
    - 滑块值变化时回调 ViewModel
    - 双击滑块重置为 0
    - 标签切换时水平滑动动画
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 7.5_

- [x] 10. 实现 UI 层 - 滤镜和裁剪
  - [x] 10.1 实现 FilterPresetView
    - 水平 UICollectionView 展示滤镜缩略图
    - 点击应用/取消滤镜
    - 当前激活滤镜高亮显示
    - _Requirements: 3.1, 3.2, 3.4, 3.5_

  - [x] 10.2 实现 CropOverlayView
    - 可拖拽调整的裁剪框
    - 宽高比选择栏
    - 旋转按钮
    - 确认/取消按钮
    - 裁剪区域外半透明遮罩
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 11. 实现图片加载和导出
  - [x] 11.1 实现 PhotoLoader
    - 使用 PHPickerViewController 选择照片
    - 从 PHAsset 加载 CIImage
    - 加载中/失败状态回调
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 11.2 实现 ExportManager
    - 调用 FilterEngine.renderFullResolution 渲染
    - 支持 JPEG（可选质量 1-100，默认 90）和 PNG 格式
    - 使用 PHPhotoLibrary 保存到相册
    - 进度和完成/失败回调
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [ ]* 11.3 导出相关单元测试
    - 测试 JPEG/PNG 格式输出
    - 测试质量参数范围验证
    - 测试导出失败错误处理
    - _Requirements: 6.2, 6.3, 6.6_

- [x] 12. 实现滤镜预设数据
  - 定义至少 10 个内置 FilterPreset
  - 涵盖风格：鲜艳、暖色、冷色、黑白、复古、柔和、戏剧、日落、森林、城市
  - 每个预设包含 id、name、icon、parameters
  - _Requirements: 3.4_

- [x] 13. 集成与串联
  - [x] 13.1 串联完整编辑流程
    - App 启动 → 选择照片 → 进入编辑器 → 调整/滤镜/裁剪 → 导出
    - 连接所有 ViewController、ViewModel、Service
    - 配置 Info.plist 相册权限描述
    - _Requirements: 1.1, 1.2, 1.3, 6.4, 6.5_

- [-] 14. 最终检查点 - 确保所有测试通过
  - 确保所有测试通过，如有问题请询问用户。

## 备注

- 标记 `*` 的任务为可选任务，可跳过以加快 MVP 进度
- 每个任务引用了具体的需求编号以便追溯
- 检查点确保增量验证
- 属性测试验证通用正确性属性
- 单元测试验证具体示例和边界条件
