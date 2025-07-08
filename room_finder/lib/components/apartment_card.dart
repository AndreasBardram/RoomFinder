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
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
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
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_page + 1}/${widget.images.length}',
                                style: TextStyle(color: Colors.white, fontSize: 11),
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
            Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  Icon(PhosphorIcons.mapPin(), size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Icon(PhosphorIcons.currencyDollarSimple(), size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${widget.price.round()} kr.',
                    style: TextStyle(fontSize: 13),
                  ),
                  Spacer(),
                  Icon(PhosphorIcons.ruler(), size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${widget.size.toStringAsFixed(0)} m²',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Icon(PhosphorIcons.calendar(), size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.period,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(PhosphorIcons.users(), size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    widget.roommates.toString(),
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
