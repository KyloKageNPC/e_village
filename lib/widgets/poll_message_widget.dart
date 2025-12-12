import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poll_model.dart';

class PollMessageWidget extends StatelessWidget {
  final PollModel poll;
  final String currentUserId;
  final Function(String optionId) onVote;

  const PollMessageWidget({
    super.key,
    required this.poll,
    required this.currentUserId,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final hasEnded = poll.hasEnded;
    final totalVotes = poll.totalVotes;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poll icon and title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.poll,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poll',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    if (hasEnded)
                      Text(
                        'Ended',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (poll.endDate != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasEnded ? Colors.red.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: hasEnded ? Colors.red.shade600 : Colors.orange.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        hasEnded ? 'Ended' : 'Ends ${dateFormat.format(poll.endDate!)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: hasEnded ? Colors.red.shade600 : Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),

          // Question
          Text(
            poll.question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),

          // Options
          ...poll.options.map((option) {
            final voteCount = option.votes.length;
            final percentage = option.getPercentage(totalVotes);
            final hasVoted = option.votes.any((v) => v.userId == currentUserId);

            return GestureDetector(
              onTap: hasEnded ? null : () => onVote(option.id),
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Option text and vote indicator
                    Row(
                      children: [
                        Icon(
                          hasVoted ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 20,
                          color: hasVoted ? Colors.orange.shade600 : Colors.black45,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: hasVoted ? FontWeight.w600 : FontWeight.normal,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '$voteCount ${voteCount == 1 ? 'vote' : 'votes'} • ${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalVotes > 0 ? percentage / 100 : 0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          hasVoted ? Colors.orange.shade600 : Colors.orange.shade300,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          SizedBox(height: 8),

          // Footer info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.how_to_vote, size: 14, color: Colors.black45),
                  SizedBox(width: 4),
                  Text(
                    '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (poll.allowMultipleVotes)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Multiple votes allowed',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (poll.isAnonymous)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_off, size: 10, color: Colors.purple.shade700),
                      SizedBox(width: 2),
                      Text(
                        'Anonymous',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
