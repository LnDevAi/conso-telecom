import 'package:flutter/material.dart';

class AiProviderBadge extends StatelessWidget {
  const AiProviderBadge({
    super.key,
    required this.providerId,
    this.showName = true,
    this.compact = false,
  });

  final String providerId;
  final bool showName;
  final bool compact;

  static const _providerConfig = {
    'anthropic': _ProviderConfig(
      color: Color(0xFFd97706),
      bgColor: Color(0xFFFFF7ED),
      initials: 'AN',
      name: 'Anthropic',
    ),
    'openai': _ProviderConfig(
      color: Color(0xFF059669),
      bgColor: Color(0xFFECFDF5),
      initials: 'OA',
      name: 'OpenAI',
    ),
    'google': _ProviderConfig(
      color: Color(0xFF1a56db),
      bgColor: Color(0xFFEFF6FF),
      initials: 'GG',
      name: 'Google',
    ),
    'mistral': _ProviderConfig(
      color: Color(0xFF7c3aed),
      bgColor: Color(0xFFF5F3FF),
      initials: 'MS',
      name: 'Mistral',
    ),
  };

  _ProviderConfig get _config =>
      _providerConfig[providerId.toLowerCase()] ??
      const _ProviderConfig(
        color: Color(0xFF6b7280),
        bgColor: Color(0xFFF3F4F6),
        initials: 'AI',
        name: 'IA',
      );

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final size = compact ? 22.0 : 26.0;
    final fontSize = compact ? 9.0 : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: config.color,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              config.initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          if (showName) ...[
            const SizedBox(width: 6),
            Text(
              config.name,
              style: TextStyle(
                color: config.color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProviderConfig {
  final Color color;
  final Color bgColor;
  final String initials;
  final String name;

  const _ProviderConfig({
    required this.color,
    required this.bgColor,
    required this.initials,
    required this.name,
  });
}
