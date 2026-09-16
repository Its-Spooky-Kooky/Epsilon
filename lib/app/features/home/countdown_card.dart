import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:epsilon/app/core/device_alarm_service.dart';
import 'package:epsilon/app/core/plugin_interface.dart';

class CountdownCard extends ConsumerStatefulWidget {
  final EventItem contest;

  const CountdownCard({super.key, required this.contest});

  @override
  ConsumerState<CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends ConsumerState<CountdownCard> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _remaining = _calculateRemaining();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant CountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contest.startTime != widget.contest.startTime) {
      _remaining = _calculateRemaining();
    }
  }

  Duration _calculateRemaining() {
    final now = DateTime.now();
    final diff = widget.contest.startTime.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (days > 0) {
      return '{0}d {1}h {2}m {3}s'.replaceFirst('{0}', days.toString()).replaceFirst('{1}', hours.toString()).replaceFirst('{2}', minutes.toString()).replaceFirst('{3}', seconds.toString());
    }
    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    return '$hStr:$mStr:$sStr';
  }

  @override
  Widget build(BuildContext context) {
    final contest = widget.contest;
    final alarmIds = ref.watch(activeDeviceAlarmIdsProvider);
    final isAlarmSet = alarmIds.contains(contest.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  contest.platform.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    contest.series,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final set = await ref.read(activeDeviceAlarmIdsProvider.notifier).toggleAlarm(contest);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(set ? 'Alarm set in Clock app' : 'Alarm unmarked (manage in Clock)'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Icon(
                      isAlarmSet ? Icons.alarm_on : Icons.alarm_add,
                      size: 18,
                      color: isAlarmSet ? Colors.tealAccent : Colors.white24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            contest.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STARTS IN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white38,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDuration(_remaining),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              if (contest.url.isNotEmpty)
                IconButton.filledTonal(
                  onPressed: () => launchUrl(
                    Uri.parse(contest.url),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
