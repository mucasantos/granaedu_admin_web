// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Painel Administrativo';

  @override
  String get loginSignInTitle => 'Entrar no Painel Administrativo';

  @override
  String get commonEmail => 'E-mail';

  @override
  String get commonPassword => 'Senha';

  @override
  String get commonLogin => 'Entrar';

  @override
  String get loginHintEmailAddress => 'Endereço de e-mail';

  @override
  String get loginHintPassword => 'Sua senha';

  @override
  String get validationEmailRequired => 'E-mail é obrigatório';

  @override
  String get validationPasswordRequired => 'Senha é obrigatória';

  @override
  String get authInvalidCredentials => 'E-mail/Senha inválidos';

  @override
  String get authAccessDenied => 'Acesso negado';

  @override
  String get verifyTitle => 'Verifique sua compra';

  @override
  String get verifyWhereCode => 'Onde está o seu código de compra?';

  @override
  String get verifyCheck => 'Verificar';

  @override
  String get verifyFieldLabel => 'Código de compra';

  @override
  String get verifyHint => 'Seu código de compra';

  @override
  String get verifyRequired => 'O código de compra é obrigatório';

  @override
  String get verifyButton => 'Verificar';

  @override
  String get notificationsPreviewTitle => 'Prévia da notificação';

  @override
  String get commonOk => 'Ok';

  @override
  String get commonNo => 'Não';

  @override
  String get dialogYesDelete => 'Sim, Excluir';

  @override
  String accountCreated(String date) {
    return 'Conta criada: $date';
  }

  @override
  String get subscriptionLabel => 'Assinatura: ';

  @override
  String enrolledCoursesTitle(int count) {
    return 'Cursos matriculados ($count)';
  }

  @override
  String get noCoursesFound => 'Nenhum curso encontrado';

  @override
  String wishlistTitle(int count) {
    return 'Lista de desejos ($count)';
  }

  @override
  String byAuthor(String author) {
    return 'Por $author';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent% concluído';
  }

  @override
  String get questionsTitle => 'Perguntas *';

  @override
  String get addQuestion => 'Adicionar Pergunta';

  @override
  String get noQuestionsFound => 'Nenhuma pergunta encontrada';

  @override
  String questionIndexTitle(int number, String title) {
    return 'P$number. $title';
  }

  @override
  String correctAnswer(String answer) {
    return 'Resposta correta: $answer';
  }

  @override
  String get quizAddQuestion => 'Adicionar Pergunta';

  @override
  String get quizUpdateQuestion => 'Atualizar Pergunta';

  @override
  String get quizEnterQuestionTitle => 'Digite o título da pergunta';

  @override
  String get quizQuestionTitleLabel => 'Título da Pergunta *';

  @override
  String get quizOptionsType => 'Tipo de opções';

  @override
  String get quizOptionTypeFour => 'Quatro opções';

  @override
  String get quizOptionTypeTwo => 'Duas opções';

  @override
  String get quizOptionA => 'Opção A';

  @override
  String get quizOptionB => 'Opção B';

  @override
  String get quizOptionC => 'Opção C';

  @override
  String get quizOptionD => 'Opção D';

  @override
  String get quizSelectCorrectAnswer => 'Selecione a resposta correta';

  @override
  String get quizValueIsRequired => 'Valor obrigatório';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get editorYoutubeUrlTitle => 'URL do vídeo do YouTube';

  @override
  String get editorImageUrlTitle => 'URL da imagem';

  @override
  String get editorNetworkVideoUrlTitle => 'URL do vídeo (rede)';

  @override
  String get editorUrlLabel => 'URL';

  @override
  String get editorEnterYoutubeUrlHint => 'Digite a URL do vídeo do YouTube';

  @override
  String get editorEnterImageUrlHint => 'Digite a URL da imagem';

  @override
  String get editorEnterVideoUrlHint => 'Digite a URL do vídeo';

  @override
  String get validationValueEmpty => 'Valor vazio';

  @override
  String get validationInvalidVideoId => 'ID de vídeo inválido';

  @override
  String get validationInvalidUrl => 'URL inválida';

  @override
  String get editorInsertUrlTitle => 'Insert URL';

  @override
  String get editorInsertImageUrlTitle => 'Insert Image URL';

  @override
  String get editorInsertVideoUrlTitle => 'Insert Video URL';

  @override
  String get editorDisplayTextLabel => 'Display Text';

  @override
  String get editorTextToDisplayHint => 'Text to Display';

  @override
  String get editorEnterUrlHint => 'Enter URL';

  @override
  String get editorEnterDescriptionPlaceholder => 'Enter Description';

  @override
  String get tooltipInsertLink => 'Insert Link';

  @override
  String get tooltipInsertImage => 'Image';

  @override
  String get tooltipInsertVideo => 'Insert Video Link';

  @override
  String get tooltipClearAll => 'Clear All';

  @override
  String get commonViewAll => 'Ver todos';

  @override
  String get dashboardLatestReviews => 'Avaliações recentes';

  @override
  String get dashboardNewUsers => 'Novos usuários';

  @override
  String get dashboardLatestPurchases => 'Compras recentes';

  @override
  String get dashboardTopCourses => 'Cursos em destaque';

  @override
  String dashboardEnrolledCourses(int count) {
    return 'Cursos matriculados: $count';
  }

  @override
  String dashboardStudentsCount(int count) {
    return '$count alunos';
  }

  @override
  String get chartLast7Days => 'Últimos 7 dias';

  @override
  String get chartLast30Days => 'Últimos 30 dias';

  @override
  String get chartSubscriptionPurchasesTitle => 'Assinaturas compradas';

  @override
  String chartPurchasesTooltip(int count) {
    return '$count compras';
  }

  @override
  String get chartNewUserRegistrationTitle => 'Novos cadastros de usuários';

  @override
  String chartUsersTooltip(int count) {
    return '$count usuários';
  }

  @override
  String get authorTotalStudents => 'Total de alunos';

  @override
  String get authorTotalCourses => 'Total de cursos';

  @override
  String get authorTotalReviews => 'Total de avaliações';

  @override
  String get dashboardTotalUsers => 'Total de Usuários';

  @override
  String get dashboardTotalEnrolled => 'Total Matriculados';

  @override
  String get dashboardTotalSubscribed => 'Total Assinantes';

  @override
  String get dashboardTotalPurchases => 'Total de Compras';

  @override
  String get dashboardTotalAuthors => 'Total de Autores';

  @override
  String get dashboardTotalCourses => 'Total de Cursos';

  @override
  String get dashboardTotalNotifications => 'Total de Notificações';

  @override
  String get dashboardTotalReviews => 'Total de Avaliações';

  @override
  String get dashboardTotalXP => 'Total de XP';

  @override
  String get dashboardAvgStreak => 'Média de Streak';

  @override
  String get dashboardActiveToday => 'Ativos Hoje';

  @override
  String get dashboardStudentsSummary => 'Resumo de Estudantes';

  @override
  String get dashboardCoursesSummary => 'Resumo de Cursos';

  @override
  String get priceStatusFree => 'Gratuito';

  @override
  String get priceStatusPremium => 'Premium';
}
