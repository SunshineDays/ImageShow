在项目中的简单示例：
if let cells = tableView.visibleCells.filter({ $0 is MessageChatImageCell }) as? [MessageChatImageCell] {
    if let imageView = cells.first(where: { $0.message.messageId == messageId }) {
        ImageShow.show(images, at: index, from: imageView.pictureImageView, in: cells.map { $0.pictureImageView })
    }
}
