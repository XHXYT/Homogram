// CustomComponent.ets
// 自定义占位节点，跨容器迁移能力
import { BuilderNode, FrameNode, NodeController } from '@kit.ArkUI';
import { Logger } from '@ohos/base';
import { HomeConstants } from '../../constants/HomeConstants';
import { getOrDownloadProfilePhoto, getThumbProfilePhotoPixelMap } from '../../utils';
import { HashMap } from '@kit.ArkTS';
import { ImageKnifeComponent, ImageKnifeOption } from '@ohos/imageknife';
import { image } from '@kit.ImageKit';

class ChatPhotoData {
  chatId: number | undefined = undefined;
  path: string | undefined = undefined;
  thumb: image.PixelMap | undefined = undefined;
}

@Builder
async function ChatPhotoBuilder(data: ChatPhotoData) {
  // Image("file://" + data.path)
  //   .height($r('app.float.avatar_image_size'))
  //   .width($r('app.float.avatar_image_size'))
  //   .clipShape(new Circle({
  //     width: HomeConstants.PROFILE_PHOTO_SIZE,
  //     height: HomeConstants.PROFILE_PHOTO_SIZE
  //   }))
  //   .id(data.chatId?.toString())
  ImageKnifeComponent({
    imageKnifeOption: new ImageKnifeOption({
      loadSrc: "file://" + data.path,
      placeholderSrc: data.thumb,
      errorholderSrc: data.thumb,
      objectFit: ImageFit.Auto,
      border: {
        radius: 50
      }
    })
  })
    .width(HomeConstants.PROFILE_PHOTO_SIZE)
    .height(HomeConstants.PROFILE_PHOTO_SIZE)
    // .clipShape(new Circle({
    //   width: HomeConstants.PROFILE_PHOTO_SIZE,
    //   height: HomeConstants.PROFILE_PHOTO_SIZE
    // }))
    .id(data.chatId?.toString())
}

export class ChatPhotoNodeController extends NodeController {
  private chatPhotoNode: BuilderNode<ChatPhotoData[]> | null = null;
  private isRemove: boolean = false;
  private callback: Function | undefined = undefined
  private data: ChatPhotoData | null = null

  makeNode(uiContext: UIContext): FrameNode | null {
    if (this.isRemove == true) {
      return null;
    }
    if (this.chatPhotoNode != null) {
      return this.chatPhotoNode.getFrameNode();
    }

    return null;
  }

  init(uiContext: UIContext, chatId: number | undefined, path: string | undefined, thumb: image.PixelMap | undefined) {
    if (this.chatPhotoNode != null) {
      return;
    }
    this.chatPhotoNode = new BuilderNode(uiContext);
    this.data = {
      chatId: chatId,
      path: path,
      thumb: thumb
    };
    this.chatPhotoNode.build(wrapBuilder<ChatPhotoData[]>(ChatPhotoBuilder), this.data);
  }

  update(chatId: number | undefined, path: string | undefined, thumb: image.PixelMap | undefined) {
    if (this.chatPhotoNode != null) {
      this.data = {
        chatId: chatId,
        path: path,
        thumb: thumb
      };
      this.chatPhotoNode.update(this.data);
    }
  }

  setCallback(callback: Function | undefined) {
    this.callback = callback
  }

  getNode(): BuilderNode<[ChatPhotoData]> | null {
    return this.chatPhotoNode;
  }

  setNode(node: BuilderNode<[ChatPhotoData]> | null) {
    this.chatPhotoNode = node;
    this.rebuild();
  }

  onRemove() {
    this.isRemove = true;
    this.rebuild();
    this.isRemove = false;
  }
}

let chatPhotoNodeMap: HashMap<number, ChatPhotoNodeController> = new HashMap();

export const createChatPhotoNode =
  (uiContext: UIContext, chatId: number | undefined, path: string | undefined, thumb: image.PixelMap | undefined): ChatPhotoNodeController | undefined => {
    let node = new ChatPhotoNodeController();
    node.init(uiContext, chatId, path, thumb);
    chatPhotoNodeMap.set(chatId, node);
    return node;
  }

export const getChatPhotoNode = (chatId: number | undefined): ChatPhotoNodeController | undefined => {
  return chatPhotoNodeMap.get(chatId);
}

export const deleteChatPhotoNode = (chatId: number | undefined) => {
  chatPhotoNodeMap.remove(chatId);
}