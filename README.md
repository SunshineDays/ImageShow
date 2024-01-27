一款点击查看图片的轻量级工具，实现放大/缩小预览动画效果。支持捏合、双击等操作

使用纯Swift编写，可以直接下载拖入项目中使用

在项目中的简单示例：

if let cells = tableView.visibleCells.filter({ $0 is MessageChatImageCell }) as? [MessageChatImageCell] {
    if let imageView = cells.first(where: { $0.message.messageId == messageId }) {
        ImageShow.show(images, at: 0, from: imageView.pictureImageView, in: cells.map { $0.pictureImageView })
    }
}
