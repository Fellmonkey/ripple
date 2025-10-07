import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/mixins/base_bloc_mixin.dart';
import '../../domain/usecases/create_gratitude.dart';
import 'create_gratitude_event.dart';
import 'create_gratitude_state.dart';

/// Create Gratitude BLoC
/// 
/// Handles gratitude creation flow
class CreateGratitudeBloc extends Bloc<CreateGratitudeEvent, CreateGratitudeState>
    with BaseBlocMixin<CreateGratitudeEvent, CreateGratitudeState> {
  final CreateGratitudeUseCase createGratitude;

  CreateGratitudeBloc({
    required this.createGratitude,
  }) : super(const CreateGratitudeInitial()) {
    on<SubmitGratitude>(_onSubmitGratitude);
    on<ResetCreateForm>(_onResetForm);
  }

  Future<void> _onSubmitGratitude(
    SubmitGratitude event,
    Emitter<CreateGratitudeState> emit,
  ) async {
    await executeWithStates(
      operation: () => createGratitude(
        userId: event.userId,
        text: event.text,
        category: event.category,
        tags: event.tags,
        point: event.point,
        photoUrl: event.photoUrl,
        parentId: event.parentId,
      ),
      loadingState: () => const CreateGratitudeSubmitting(),
      successState: (gratitude) => CreateGratitudeSuccess(gratitude),
      errorState: (error) => CreateGratitudeError(error),
      emit: emit,
      operationName: 'Create gratitude',
    );
  }

  Future<void> _onResetForm(
    ResetCreateForm event,
    Emitter<CreateGratitudeState> emit,
  ) async {
    emit(const CreateGratitudeInitial());
  }
}
