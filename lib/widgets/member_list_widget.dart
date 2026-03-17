import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../services/calendar_service.dart';
import '../utils/globals.dart';

class MemberListWidget extends StatelessWidget {
  final List<MemberModel> members;
  final String ownerId;
  final bool isOwner;
  final String calendarId;

  const MemberListWidget({
    super.key,
    required this.members,
    required this.ownerId,
    required this.isOwner,
    required this.calendarId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: members.map((m) => _buildMemberTile(context, m)).toList(),
    );
  }

  Widget _buildMemberTile(BuildContext context, MemberModel member) {
    final isOwnerMember = member.uid == ownerId;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _roleColor(member.role).withOpacity(0.2),
        child: Text(
          (member.displayName ?? member.email ?? '?')
              .characters
              .first
              .toUpperCase(),
          style: TextStyle(
            color: _roleColor(member.role),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        member.displayName ?? member.email ?? 'Usuario',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _roleLabel(member.role),
        style: TextStyle(
          fontSize: 12,
          color: _roleColor(member.role),
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: isOwner && !isOwnerMember
          ? PopupMenuButton<String>(
              onSelected: (action) =>
                  _handleAction(context, action, member),
              itemBuilder: (_) => [
                if (member.role != MemberRole.editor)
                  const PopupMenuItem(
                    value: 'editor',
                    child: Text('Promover a editor'),
                  ),
                if (member.role != MemberRole.viewer)
                  const PopupMenuItem(
                    value: 'viewer',
                    child: Text('Degradar a viewer'),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remover',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            )
          : null,
    );
  }

  void _handleAction(
      BuildContext context, String action, MemberModel member) async {
    try {
      if (action == 'remove') {
        await CalendarService.removeMember(
          calendarId: calendarId,
          uid: member.uid,
        );
      } else {
        final role = action == 'editor' ? MemberRole.editor : MemberRole.viewer;
        await CalendarService.updateMemberRole(
          calendarId: calendarId,
          uid: member.uid,
          role: role,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _roleLabel(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return 'Administrador';
      case MemberRole.editor:
        return 'Editor';
      case MemberRole.viewer:
        return 'Visor';
    }
  }

  Color _roleColor(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return AppColors.soka;
      case MemberRole.editor:
        return Colors.orange;
      case MemberRole.viewer:
        return AppColors.grey;
    }
  }
}
