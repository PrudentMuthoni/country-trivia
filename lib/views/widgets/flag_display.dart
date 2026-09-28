import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class FlagDisplay extends StatelessWidget {
  final String isoCode;

  const FlagDisplay({super.key, required this.isoCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: CachedNetworkImage(
            imageUrl: AppConstants.flagUrl(isoCode),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
