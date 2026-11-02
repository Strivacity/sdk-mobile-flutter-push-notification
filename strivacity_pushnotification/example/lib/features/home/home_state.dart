import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

enum HomeStatus { loading, ready, failure }

enum HomeNoticeKind { success, info, error }

/// A one-time message for the user.
typedef HomeNotice = ({String message, HomeNoticeKind kind});

typedef HomeState = ({
  HomeStatus status,

  List<Enrollment> enrollments,

  /// A valid scanned grant awaiting a device name.
  EnrollmentGrant? pendingGrant,

  /// Enrolling the device.
  bool enrolling,

  /// The backend is being told about a new push token.
  bool tokenUpdating,

  /// Enrollments the backend refused a new push token for, until the user has been told.
  List<Enrollment>? tokenUpdateFailures,

  /// Null once shown.
  HomeNotice? notice,
});

extension HomeStateCopy on HomeState {
  /// A copy with the given fields replaced. A nullable field takes a function returning its new
  /// value, so that null can be set: `copyWith(pendingGrant: () => null)`.
  HomeState copyWith({
    HomeStatus? status,
    List<Enrollment>? enrollments,
    EnrollmentGrant? Function()? pendingGrant,
    bool? enrolling,
    bool? tokenUpdating,
    List<Enrollment>? Function()? tokenUpdateFailures,
    HomeNotice? Function()? notice,
  }) => (
    status: status ?? this.status,
    enrollments: enrollments ?? this.enrollments,
    pendingGrant: pendingGrant == null ? this.pendingGrant : pendingGrant(),
    enrolling: enrolling ?? this.enrolling,
    tokenUpdating: tokenUpdating ?? this.tokenUpdating,
    tokenUpdateFailures: tokenUpdateFailures == null ? this.tokenUpdateFailures : tokenUpdateFailures(),
    notice: notice == null ? this.notice : notice(),
  );
}
