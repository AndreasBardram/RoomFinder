import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ApartmentCard extends StatefulWidget {
  final List<String> images;
  final String title;
  final String location;
  final num price;
  final double size;
  final String period;
  final int roommates;

  const ApartmentCard({
    Key? key,
    required this.images,
    required this.title,
    required this.location,
    required this.price,
    required this.size,
    required this.period,
    required this.roommates,
  }) : super(key: key);

  @override
  State<ApartmentCard> createState() => _ApartmentCardState();
}

class _ApartmentCardState extends State<ApartmentCard> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final hasImg = widget.images.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 1,
              child: hasImg
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: widget.images.length,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: widget.images[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[200],
                              child: Center(child: Icon(PhosphorIcons.image())),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: Center(child: Icon(PhosphorIcons.imageSquare())),
                            ),
                          ),
                        ),
                        if (widget.images.length > 1)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_page + 1}/${widget.images.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(child: Icon(PhosphorIcons.image(), size: 50)),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                Icon(PhosphorIcons.mapPin(), size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Icon(PhosphorIcons.currencyDollarSimple(), size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${widget.price.round()} kr.',
                  style: const TextStyle(fontSize: 13),
                ),
                const Spacer(),
                Icon(PhosphorIcons.ruler(), size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${widget.size.toStringAsFixed(0)} m²',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Icon(PhosphorIcons.calendar(), size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.period,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(PhosphorIcons.users(), size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  widget.roommates.toString(),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
