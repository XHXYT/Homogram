import { BaseConstants, BreakpointConstants, DateHelper, IntroduceText, Logger, NormalText } from '@ohos/base'
import {
  MediaType,
  downloadMediaFromMessage,
  getProfilePhotoPathAndCount,
  NativeSeenChat,
  downloadProfilePhoto,
  ChatType
} from 'libhomogrape.so';
import { HomeConstants } from '../../constants/HomeConstants';
import { Message } from '../../entities/Message';
import { fileIo as fs, ReadOptions } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { HashMap } from '@kit.ArkTS';
import { SeenChat } from '../../entities/SeenChat';
import { getOrDownloadProfilePhoto, getThumbProfilePhotoPixelMap } from '../../utils';
import { ReplyToPreview } from './ReplyToPreview'
import { MessageDataSource } from '../../viewmodel/Message/MessageDataSource';

@Component
export struct MessageBubble {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  avatar1: Resource = $r('app.media.avatar1');
  avatar2: Resource = $r('app.media.avatar7');
  @Consume me: NativeSeenChat | undefined;
  @Consume seenChatsMap: HashMap<string, SeenChat>;
  @Consume messagesOfChatMap: HashMap<string, MessageDataSource>;
  @State mediaPath: string = "";
  @State mediaLoaded: boolean = false;
  @State mediaLoadFailed: boolean = false;
  @State profilePhotoPath: string | undefined = undefined;
  @State profilePhotoLoaded: boolean = false;
  @State profilePhotoLoadFailed: boolean = false;
  @State profilePhotoPixelMap: PixelMap | undefined = undefined;
  @Consume currentChatId: string;
  @Consume isScrollingDueToReplyToMessage: boolean;
  @Consume scrollToRepliedMessageIndex: number;
  private messageListScroller?: ListScroller;
  private chatType: ChatType = ChatType.User;
  private content: string = "";
  private isAppletMsg?: boolean = false;
  private isDocumentMsg?: boolean = false;
  private message? = new Message(
    1,
    1,
    false,
    false,
    1,
    "John Doe",
    Date.now(),
    "Hello, World!",
    MediaType.None,
    0,
    0,
    0,
  );

  build() {
    Column() {
      Flex({
        justifyContent: !this.message?.outgoing ? FlexAlign.Start : FlexAlign.End,
        direction: FlexDirection.Row
      }) {
        if ((!this.message?.outgoing) && (this.chatType != ChatType.User)) {
          Image("file://" + this.profilePhotoPath)
            .width(HomeConstants.PROFILE_PHOTO_SIZE_SMALL)
            .height(HomeConstants.PROFILE_PHOTO_SIZE_SMALL)
            .flexShrink(BaseConstants.FLEX_SHRINK_ZERO)
            .clipShape(new Circle({
              width: HomeConstants.PROFILE_PHOTO_SIZE_SMALL,
              height: HomeConstants.PROFILE_PHOTO_SIZE_SMALL
            }))
            .onAppear(() => {
              getOrDownloadProfilePhoto(this.message?.senderId || 0)
                .then((path) => {
                  this.profilePhotoPath = path;
                  this.profilePhotoLoaded = true;
                });
            })
        }
        Column() {
          Stack({ alignContent: !this.message?.outgoing ? Alignment.TopStart : Alignment.TopEnd }) {
            Column() {
              if ((!this.message?.outgoing) && (this.chatType != ChatType.User)) {
                Row() {
                  Text(this.message?.senderName)
                    .fontSize(10)// .fontColor(Color.Black)
                    .fontWeight(FontWeight.Bold)
                    .textAlign(TextAlign.Start)
                  Blank()
                }
                .alignSelf(ItemAlign.Start)
              }

              Column() {
                // reply to message
                if (this.message?.replyToMessageId && this.message?.replyToMessageId != -1) {
                  ReplyToPreview({
                    replyToMessageId: this.message?.replyToMessageId
                  })
                    .alignSelf(!this.message?.outgoing ? ItemAlign.Start : ItemAlign.End)
                    .margin({
                      top: HomeConstants.MESSAGE_REPLY_TO_PREVIEW_TOP_MARGIN,
                    })
                    .onClick(() => {
                      Logger.debug("ReplyToPreview onClick: " + this.message?.replyToMessageId + " currentChatId: " +
                      this.currentChatId);
                      let target_index =
                        this.messagesOfChatMap.get(this.currentChatId)?.indexOf(this.message?.replyToMessageId || -1);
                      Logger.debug("ReplyToPreview onClick: target_index: " + target_index);
                      let current_index =
                        this.messagesOfChatMap.get(this.currentChatId)?.indexOf(this.message?.messageId || -1);
                      Logger.debug("ReplyToPreview onClick: current_index: " + current_index);

                      if (target_index === undefined || target_index < 0 || target_index === null) {
                        Logger.error("ReplyToPreview onClick: error, index is " + target_index);
                        return;
                      }
                      if (current_index - target_index > BaseConstants.LAZY_FOR_EACH_SCROLL_INDEX_LIMIT) {
                        Logger.debug("ReplyToPreview onClick: gap is too large, scroll to target in two steps");
                        this.isScrollingDueToReplyToMessage = true;
                        this.scrollToRepliedMessageIndex = target_index;
                        this.messageListScroller?.scrollToIndex(current_index -
                        BaseConstants.LAZY_FOR_EACH_SCROLL_INDEX_LIMIT +
                        BaseConstants.LAZY_FOR_EACH_SCROLL_SMOOTH_BUFFER,
                          true,
                          ScrollAlign.CENTER);
                        Logger.debug("ReplyToPreview onClick: scrollToIndex first step: " +
                          (current_index -
                          BaseConstants.LAZY_FOR_EACH_SCROLL_INDEX_LIMIT +
                          BaseConstants.LAZY_FOR_EACH_SCROLL_SMOOTH_BUFFER));
                      } else {
                        Logger.debug("ReplyToPreview onClick: scroll to target in one step");
                        this.messageListScroller?.scrollToIndex(target_index, true, ScrollAlign.CENTER);
                      }
                    })
                    .alignSelf(ItemAlign.Start)
                }
                if (this.message?.mediaType === MediaType.Photo) {
                  this.Media()
                }
                this.MessageContent()
                Row() {
                  Blank()
                  Text(DateHelper.getParsedDateString(this.message?.timestamp))
                    .fontSize(8)
                    .fontColor(HomeConstants.MESSAGE_TIME_COLOR)
                  if (this.message?.outgoing) {
                    Text(' ')
                    Text() {
                      SymbolSpan($r('sys.symbol.checkmark_circle'))
                    }
                    // .fontColor(HomeConstants.MESSAGE_TIME_COLOR)
                    .fontSize(8)
                  }
                }
                .alignSelf(ItemAlign.End)
              }
              // .justifyContent(FlexAlign.Start)
              // .alignItems(HorizontalAlign.Start)
              .alignSelf(ItemAlign.Start)
            }
            .padding({
              left: 8,
              right: 8,
              top: 8,
              bottom: 8
            })
            .backgroundColor(!this.message?.outgoing ? HomeConstants.MESSAGE_BACKGROUND_COLOR :
            HomeConstants.MESSAGE_BACKGROUND_COLOR_OUTGOING)
            .borderRadius(HomeConstants.PATH_BORDER_RADIUS)
          }
          .padding({
            top: 5,
            // left: $r('app.float.path_left'),
            // right: $r('app.float.path_right'),
            bottom: 5
          })
          .width(BaseConstants.NINETY_WIDTH_PERCENT)
        }
        .width(BaseConstants.NINETY_WIDTH_PERCENT)

        // if (this.message?.outgoing) {
        // Image("file://" + this.profilePhotoPath)
        //   .width(HomeConstants.PROFILE_PHOTO_SIZE_SMALL)
        //   .height(HomeConstants.PROFILE_PHOTO_SIZE_SMALL)
        //   .flexShrink(BaseConstants.FLEX_SHRINK_ZERO)
        //   .clipShape(new Circle({
        //     width: HomeConstants.PROFILE_PHOTO_SIZE_SMALL,
        //     height: HomeConstants.PROFILE_PHOTO_SIZE_SMALL
        //   }))
        //   .onAppear(() => {
        //     // getThumbProfilePhotoPixelMap(this.me?.chatId.toString(), this.seenChatsMap)
        //     //   .then((pixelMap) => {
        //     //     this.profilePhotoPixelMap = pixelMap;
        //     //   })
        //     //   .catch((e: Error) => {
        //     //     Logger.error("ChatDetailItem: failed to create pixel map: " + e);
        //     //   });
        //     getOrDownloadProfilePhoto(this.me?.chatId || 0)
        //       .then((path) => {
        //         this.profilePhotoPath = path;
        //         this.profilePhotoLoaded = true;
        //       })
        //       .catch((error: Error) => {
        //         Logger.error("ChatDetailItem: failed to get or download profile photo: " + error);
        //         this.profilePhotoLoadFailed = true;
        //       });
        //   })
        // }
      }
      .flexShrink(BaseConstants.FLEX_SHRINK_ONE)
    }
    .margin({ left: 5, right: 5 })
  }

  @Builder
  MessageContent() {
    Text(this.message?.text)
      .fontSize(BaseConstants.FONT_SIZE_TWELVE)
      .fontFamily(BaseConstants.FONT_FAMILY_NORMAL)
      .fontWeight(BaseConstants.FONT_WEIGHT_FOUR)
      .lineHeight($r('app.float.chat_default_text_line'))
      .fontColor($r('sys.color.ohos_id_color_text_primary'))
      .copyOption(CopyOptions.LocalDevice)
      .alignSelf(ItemAlign.Start)
  }

  @Builder
  Media() {
    Stack() {
      Flex() {
      }
      .height($r('app.float.applet_image_height'))
      .width($r('app.float.applet_image_width'))
      .backgroundImage("file://" + this.mediaPath)
      // .backgroundImageSize({
      //   width: $r('app.float.applet_image_width'),
      //   height: $r('app.float.applet_image_height')
      // })
      .backgroundImageSize(ImageSize.Contain)
      .constraintSize({ maxWidth: BaseConstants.FULL_WIDTH })
      .margin({ bottom: $r('app.float.applet_image_bottom') })

      if (!this.mediaLoaded) {
        if (this.mediaLoadFailed) {
          Text("Retry")
            .fontColor(Color.Red)
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .onClick(() => {
              this.loadMedia()
            })
        } else {
          LoadingProgress()
            .color(Color.Blue)
            .layoutWeight(1)
            .size({
              width: "10%",
              height: "10%"
            })
        }
      }
    }
    .alignSelf(ItemAlign.Start)
    .onAppear(() => {
      this.loadMedia();
    })
    .onClick(() => {
      this.mediaPath =
        BaseConstants.BASE_DIR + this.message?.chatId.toString() + "/" + this.message?.messageId.toString() + ".jpg";
      Logger.debug("Media onClick: " + this.mediaPath);
      if (!fs.accessSync(this.mediaPath)) {
        Logger.debug("Media onClick: media not exists, downloading media");
        this.loadMedia();
      }

      // TODO: show media in full screen
    })
  }

  loadMedia() {
    this.mediaLoaded = false;
    this.mediaLoadFailed = false;
    this.mediaPath =
      BaseConstants.BASE_DIR + this.message?.chatId.toString() + "/" + this.message?.messageId.toString() + ".jpg";
    Logger.debug("Media onAppear: " + this.mediaPath);
    // download the image if not exists
    if (!fs.accessSync(this.mediaPath)) {
      Logger.debug("Media onAppear: media not exists, downloading media");
      downloadMediaFromMessage(this.message?.chatId, this.message?.messageId)
        .then((path) => {
          Logger.debug("Media onAppear: media downloaded: " + path);
          this.mediaPath = path;
          this.mediaLoaded = true;
        })
        .catch((error: Error) => {
          Logger.debug("Media onAppear Failed to download media: " + error.message);
          this.mediaLoadFailed = true;
        });
    } else {
      Logger.debug("Media onAppear: media exists");
      this.mediaLoaded = true;
    }
  }
}