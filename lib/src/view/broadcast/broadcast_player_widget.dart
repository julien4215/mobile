import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/styles/federation_icons.dart';
import 'package:lichess_mobile/src/styles/styles.dart';

class BroadcastPlayerWidget extends ConsumerWidget {
  const BroadcastPlayerWidget({
    required this.federation,
    required this.title,
    required this.name,
    this.rating,
    this.textStyle,
  });

  final String? federation;
  final String? title;
  final int? rating;
  final String name;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        if (federation != null) ...[
          Icon(federationIcons[federation]),
          const SizedBox(width: 5),
        ],
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle().copyWith(
              color: context.lichessColors.brag,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            name,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (rating != null) ...[
          const SizedBox(width: 5),
          Text(
            rating.toString(),
            style: const TextStyle(),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
