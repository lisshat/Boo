import 'package:flutter/material.dart';
import 'package:boo/models/provider_models.dart';
import 'package:boo/services/reviews_service.dart';

class ProviderReviewsScreen extends StatefulWidget {
  const ProviderReviewsScreen({super.key});

  @override
  State<ProviderReviewsScreen> createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends State<ProviderReviewsScreen> {
  static const _orange = Color(0xFFF68B1F);
  static const _bg = Color(0xFFF6F7FB);

  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final reviews = await ReviewsService.instance.getMyProviderReviews();
      if (mounted) setState(() { _reviews = reviews; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not load reviews'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Reviews', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load, tooltip: 'Refresh'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.black45)),
                      TextButton(onPressed: _load, child: const Text('Retry', style: TextStyle(color: _orange))),
                    ],
                  ),
                )
              : _reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_outline_rounded, size: 52, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No reviews yet', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Reviews from pet owners will appear here',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _orange,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _ReviewCard(
                          review: _reviews[i],
                          onReplied: _load,
                        ),
                      ),
                    ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onReplied;

  const _ReviewCard({required this.review, required this.onReplied});

  static const _orange = Color(0xFFF68B1F);

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays >= 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: owner + stars + time
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _orange.withOpacity(0.12),
                child: Text(
                  review.ownerName.isNotEmpty ? review.ownerName[0].toUpperCase() : '?',
                  style: const TextStyle(color: _orange, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.ownerName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 14,
                          color: Colors.amber,
                        )),
                        const SizedBox(width: 6),
                        Text(_timeAgo(review.createdAt),
                            style: const TextStyle(fontSize: 11, color: Colors.black38)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Review text
          if (review.text != null && review.text!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.text!,
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
          ],

          // Provider reply
          if (review.providerReply != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your reply',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black45)),
                  const SizedBox(height: 4),
                  Text(review.providerReply!,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                ],
              ),
            ),
          ],

          // Reply button (only when no reply yet)
          if (review.providerReply == null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showReplySheet(context),
              icon: const Icon(Icons.reply_rounded, size: 16),
              label: const Text('Reply', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _orange,
                side: BorderSide(color: _orange.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReplySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReplySheet(reviewId: review.id, onSaved: onReplied),
    );
  }
}

class _ReplySheet extends StatefulWidget {
  final String reviewId;
  final VoidCallback onSaved;

  const _ReplySheet({required this.reviewId, required this.onSaved});

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  static const _orange = Color(0xFFF68B1F);
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final ok = await ReviewsService.instance.replyToReview(widget.reviewId, _ctrl.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply posted'), backgroundColor: _orange, duration: Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not post reply'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reply to Review', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Write your response...',
              hintStyle: const TextStyle(color: Colors.black26),
              filled: true,
              fillColor: const Color(0xFFF6F7FB),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                disabledBackgroundColor: _orange.withOpacity(0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Post Reply', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
