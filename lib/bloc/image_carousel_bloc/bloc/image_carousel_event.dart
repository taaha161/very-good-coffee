part of 'image_carousel_bloc.dart';

sealed class ImageCarouselEvent extends Equatable {
  const ImageCarouselEvent();

  @override
  List<Object> get props => [];
}

class NetworkImagesLoadEvent extends ImageCarouselEvent {}

class LocalImagesLoadEvent extends ImageCarouselEvent {}

class NextNetworkImagesEvent extends ImageCarouselEvent {}

class ImageLikeEvent extends ImageCarouselEvent {
  final String
      imageUrl; // We need the image url to uniquely identify each image's path
  const ImageLikeEvent({required this.imageUrl});

  @override
  List<Object> get props => [imageUrl];
}

class ImageDisLikeEvent extends ImageCarouselEvent {
  final String
      imageUrl; // We need the image url to uniquely identify each image's path
  const ImageDisLikeEvent({required this.imageUrl});

  @override
  List<Object> get props => [imageUrl];
}
