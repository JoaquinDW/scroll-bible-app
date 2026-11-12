import Foundation

/// Every user-facing string, in English and Spanish, in one place.
/// Scripture, explanations and questions live in Resources/content.json instead.
/// Tone: an invitation. Never guilt, never promises of spiritual, medical or mental-health outcomes.
enum Copy {
    // MARK: General
    static let continueLabel = LText("Continue", "Continuar")
    static let done = LText("Done", "Listo")
    static let close = LText("Close", "Cerrar")
    static let back = LText("Back", "Atrás")
    static let skipForNow = LText("Skip for now", "Omitir por ahora")
    static let comingSoon = LText("More readings are on the way.", "Vienen más lecturas en camino.")
    static let you = LText("You", "Tú")
    static let sheepGeneric = LText("Your sheep", "Tu oveja")
    static let dayN = LText("Day %ld", "Día %ld")
    static let daysN = LText("%ld days", "%ld días")
    static let minutesADay = LText("%ld minutes a day", "%ld minutos al día")
    static let recommended = LText("A good place to start", "Un buen punto de partida")
    static let publicDomain = LText("Public domain", "Dominio público")

    // MARK: Tabs
    static let tabHome = LText("Today", "Hoy")
    static let tabJourneys = LText("Journeys", "Caminos")
    static let tabFlock = LText("Flock", "Rebaño")
    static let tabProgress = LText("Progress", "Progreso")

    // MARK: Welcome
    static let welcomePromise = LText("Trade 5 minutes of scrolling for the Word", "Cambia 5 minutos de scroll por la Palabra")
    static let welcomeBody = LText("A short, quiet reading each day, with a little sheep for company.", "Una lectura breve y tranquila cada día, con una ovejita de compañía.")
    static let welcomeStart = LText("Begin", "Comenzar")

    // MARK: Onboarding
    static let onbLanguageTitle = LText("Which language feels like home?", "¿Qué idioma sientes como tu casa?")
    static let onbLanguageBody = LText("You can change it any time.", "Puedes cambiarlo cuando quieras.")
    static let onbTranslationTitle = LText("Choose a translation", "Elige una traducción")
    static let onbTranslationBody = LText("This is the Bible text you will read.", "Este es el texto bíblico que vas a leer.")
    static let onbTranslationNote = LText("More translations will be added as licenses allow.", "Se añadirán más traducciones a medida que las licencias lo permitan.")
    static let onbGoalTitle = LText("What brings you here?", "¿Qué te trae por aquí?")
    static let onbGoalBody = LText("We will shape your plan around it.", "Daremos forma a tu plan según eso.")
    static let onbTimeTitle = LText("How much time each day?", "¿Cuánto tiempo cada día?")
    static let onbTimeBody = LText("Short is fine. Every session has a clear end.", "Poco está bien. Cada sesión tiene un final claro.")
    static let onbReminderTitle = LText("A gentle invitation", "Una invitación amable")
    static let onbReminderBody = LText("One reminder a day, at the time you choose. Nothing more.", "Un recordatorio al día, a la hora que elijas. Nada más.")
    static let onbReminderToggle = LText("Daily reminder", "Recordatorio diario")
    static let reminderTime = LText("Time", "Hora")
    static let onbReminderExample = LText("It will sound like this: \"%@ is waiting in the sun.\"", "Sonará así: \"%@ te espera al sol.\"")
    static let onbNameTitle = LText("Name your sheep", "Ponle nombre a tu oveja")
    static let onbNameBody = LText("This little one walks with you, day by day.", "Esta pequeña camina contigo, día a día.")
    static let onbNamePlaceholder = LText("Name", "Nombre")
    static let onbFriendTitle = LText("Walk with a friend?", "¿Caminar con un amigo?")
    static let onbFriendBody = LText("Reading together helps it stick. You can also do this later.", "Leer juntos ayuda a mantener el hábito. También puedes hacerlo después.")
    static let inviteFriend = LText("Invite a friend", "Invitar a un amigo")
    static let inviteMessage = LText("I'm reading the Bible a few minutes a day with %@. Want to join my flock?", "Estoy leyendo la Biblia unos minutos al día con %@. ¿Te unes a mi rebaño?")
    static let onbPlanTitle = LText("%@ is ready", "%@ ya está lista")
    static let onbPlanBody = LText("Here is your plan. Your first reading is waiting.", "Este es tu plan. Tu primera lectura te espera.")
    static let onbStart = LText("Go to the meadow", "Ir al prado")

    static func goalTitle(_ goal: Goal) -> LText {
        switch goal {
        case .habit: return LText("Build a daily habit", "Crear un hábito diario")
        case .understand: return LText("Understand what I read", "Entender lo que leo")
        case .replaceScrolling: return LText("Scroll less, read more", "Menos scroll, más lectura")
        }
    }

    static func goalBody(_ goal: Goal) -> LText {
        switch goal {
        case .habit: return LText("A few minutes, every day.", "Unos minutos, cada día.")
        case .understand: return LText("Plain explanations beside each verse.", "Explicaciones sencillas junto a cada versículo.")
        case .replaceScrolling: return LText("A calmer first thing to open.", "Algo más tranquilo para abrir primero.")
        }
    }

    static func goalSymbol(_ goal: Goal) -> String {
        switch goal {
        case .habit: return "calendar"
        case .understand: return "lightbulb.fill"
        case .replaceScrolling: return "iphone.slash"
        }
    }

    // MARK: Paywall
    static let paywallTitle = LText("More room to grow with %@ Premium", "Más espacio para crecer con %@ Premium")
    static let paywallFree = LText("Your daily reading is always free", "Tu lectura diaria siempre es gratis")
    static let paywallBenefitFocus = LText("Focus Mode: read before your chosen apps open", "Modo Enfoque: lee antes de que se abran las apps que elijas")
    static let paywallBenefitJourneys = LText("Every Journey as it is released", "Todos los Caminos a medida que salgan")
    static let paywallBenefitFlock = LText("Bigger flocks and shared challenges", "Rebaños más grandes y desafíos compartidos")
    static let paywallBenefitStudy = LText("Deeper study notes on each passage", "Notas de estudio más profundas en cada pasaje")
    static let planAnnual = LText("Yearly", "Anual")
    static let planAnnualPrice = LText("%@ per year (placeholder price)", "%@ al año (precio provisional)")
    static let planWeekly = LText("Weekly", "Semanal")
    static let planWeeklyPrice = LText("%@ per week (placeholder price)", "%@ a la semana (precio provisional)")
    static let paywallCTA = LText("Continue with Premium", "Continuar con Premium")
    static let paywallNotNow = LText("Continue for free", "Continuar gratis")
    static let paywallFinePrint = LText("No purchase happens in this preview build. Cancel any time once billing is live.", "No se realiza ninguna compra en esta versión de prueba. Cancela cuando quieras una vez que los pagos estén activos.")

    // MARK: Home
    static let homeToday = LText("Today's reading", "Lectura de hoy")
    static let homeStart = LText("Start today's reading", "Empezar la lectura de hoy")
    static let homeSessionMeta = LText("%@ · %ld cards · about %ld min", "%@ · %ld tarjetas · unos %ld min")
    static let homeDoneTitle = LText("Today is complete", "Hoy está completo")
    static let homeDoneBody = LText("%@ is resting in the light. The rest of the day is yours.", "%@ descansa en la luz. El resto del día es tuyo.")
    static let homeTomorrow = LText("Tomorrow: %@", "Mañana: %@")
    static let homeJourney = LText("Current Journey", "Camino actual")

    // MARK: Session
    static let understandIt = LText("Understand it", "Entenderlo")
    static let understandPlain = LText("In plain words", "En palabras sencillas")
    static let understandContext = LText("Then and there", "En su tiempo")
    static let understandApply = LText("For today", "Para hoy")
    static let studyAid = LText("Study aid", "Ayuda de estudio")
    static let studyAidNote = LText("Study aids are written to help you read. They are not Scripture, and they aim to stay close to the text without taking a denominational side.", "Las ayudas de estudio se escriben para acompañar tu lectura. No son la Escritura, y procuran mantenerse fieles al texto sin tomar partido por una denominación.")
    static let saveVerse = LText("Save verse", "Guardar versículo")
    static let saved = LText("Saved", "Guardado")
    static let shareVerse = LText("Share verse", "Compartir versículo")
    static let finish = LText("Finish", "Terminar")
    static let answerFirst = LText("Take your time. Answer to continue.", "Tómate tu tiempo. Responde para continuar.")
    static let notQuite = LText("Not quite. Have another look.", "Casi. Míralo otra vez.")
    static let checkMissingTitle = LText("Which word is missing?", "¿Qué palabra falta?")
    static let checkOrderTitle = LText("Tap the verses in order", "Toca los versículos en orden")

    // MARK: Completion
    static let doneTitle = LText("The light grew today", "La luz creció hoy")
    static let doneExtraTitle = LText("A little more time in the Word", "Un rato más en la Palabra")
    static let doneFoundTitle = LText("%@ is home", "%@ está en casa")
    static let doneStreak = LText("%ld days in the light", "%ld días en la luz")
    static let doneRestored = LText("Found, and your light of %ld days is back", "Encontrada, y tu luz de %ld días ha vuelto")
    static let doneNewLight = LText("Found. A new light begins today", "Encontrada. Hoy empieza una luz nueva")
    static let doneLevel = LText("New level: %@", "Nuevo nivel: %@")
    static let doneMilestone = LText("Your meadow has something new: %@", "Tu prado tiene algo nuevo: %@")
    static let doneItem = LText("%@ found a gift: %@", "%@ encontró un regalo: %@")
    static let doneFreeze = LText("You earned a rest day for the light", "Ganaste un día de descanso para la luz")
    static let doneUnlocked = LText("Your apps are open for the rest of the day", "Tus apps quedan abiertas por el resto del día")
    static let doneCTA = LText("Back to the meadow", "Volver al prado")

    // MARK: Lost sheep
    static let lostTitle = LText("%@ wandered off", "%@ se alejó")
    static let lostShort = LText("It happens. A short reading brings your sheep home.", "A veces pasa. Una lectura breve trae a tu oveja de vuelta.")
    static let lostBody = LText("A day slipped by and the light dimmed to dusk. Nothing is lost for good. Read today and your sheep comes home.", "Pasó un día y la luz bajó hasta el atardecer. Nada se pierde para siempre. Lee hoy y tu oveja vuelve a casa.")
    static let lostVerse = LText("\"Rejoice with me; for I have found my sheep which was lost.\" Luke 15:6", "\"Dadme el parabién, porque he hallado mi oveja que se había perdido.\" Lucas 15:6")
    static let lostRecoveryFree = LText("This week's free return is ready: your %ld days come back with you.", "El regreso gratis de esta semana está listo: tus %ld días vuelven contigo.")
    static let lostRecoveryUsed = LText("This week's free return is used, so a new light begins today.", "El regreso gratis de esta semana ya se usó, así que hoy empieza una luz nueva.")
    static let lostCTA = LText("Bring %@ home", "Traer a %@ a casa")

    // MARK: Journeys
    static let journeysTitle = LText("Journeys", "Caminos")
    static let journeyProgress = LText("%ld of %ld days", "%ld de %ld días")
    static let journeyComingSoon = LText("This Journey is being prepared.", "Este Camino se está preparando.")
    static let journeyMakeCurrent = LText("Walk this Journey", "Recorrer este Camino")

    // MARK: Progress
    static let progressTitle = LText("Progress", "Progreso")
    static let levelN = LText("Level %ld", "Nivel %ld")
    static let levelNext = LText("%ld XP to %@", "%ld XP para %@")
    static let statLight = LText("Light", "Luz")
    static let statBest = LText("Longest", "Récord")
    static let statFreezes = LText("Rest days", "Descansos")
    static let scenesTitle = LText("Meadow scenes", "Escenas del prado")
    static let itemsTitle = LText("Gifts for %@", "Regalos para %@")
    static let booksTitle = LText("Books of the Bible", "Libros de la Biblia")
    static let booksNote = LText("A tile fills with color once you have read from that book.", "Una casilla se llena de color cuando has leído de ese libro.")
    static let savedTitle = LText("Saved verses", "Versículos guardados")
    static let savedEmpty = LText("Tap the heart on any verse to keep it here.", "Toca el corazón en cualquier versículo para guardarlo aquí.")

    // MARK: Flock
    static let flockTitle = LText("Your flock", "Tu rebaño")
    static let flockSample = LText("Sample flock", "Rebaño de ejemplo")
    static let leagueTitle = LText("This week's league", "Liga de esta semana")
    static let daysLeft = LText("%ld days left", "Quedan %ld días")
    static let leagueNote = LText("Friendly by design: everyone who reads moves forward.", "Amistosa por diseño: todo el que lee avanza.")
    static let challengeTitle = LText("Read Ruth together", "Leer Rut juntos")
    static let challengeBody = LText("Four short chapters this week, as a flock.", "Cuatro capítulos cortos esta semana, como rebaño.")
    static let challengeProgress = LText("%ld of %ld chapters read by the flock", "%ld de %ld capítulos leídos por el rebaño")
    static let nudgeTitle = LText("A gentle nudge", "Un toquecito amable")
    static let nudgeWaiting = LText("%@ has not been out in the sun yet today", "%@ aún no ha salido al sol hoy")
    static let nudgeCTA = LText("Nudge", "Avisar")
    static let nudgeSent = LText("Sent", "Enviado")
    static let nudgeNote = LText("They will see: \"Saving you a spot in the meadow.\"", "Verán: \"Te guardo un lugar en el prado.\"")

    // MARK: Focus Mode
    static let focusTitle = LText("Focus Mode", "Modo Enfoque")
    static let focusHeadline = LText("Read first, then scroll", "Primero lee, luego desliza")
    static let focusBody = LText("Choose the apps that pull at you. They stay closed until today's reading is done, then open for the rest of the day.", "Elige las apps que más te atrapan. Quedan cerradas hasta terminar la lectura de hoy y luego se abren por el resto del día.")
    static let focusPremium = LText("Focus Mode is part of Premium.", "El Modo Enfoque es parte de Premium.")
    static let focusSeePlans = LText("See plans", "Ver planes")
    static let focusToggle = LText("Shield apps until I read", "Bloquear apps hasta que lea")
    static let focusChoose = LText("Choose apps", "Elegir apps")
    static let focusChosen = LText("%ld selected. Change", "%ld seleccionadas. Cambiar")
    static let focusLocked = LText("Shield is on until today's reading is done.", "El bloqueo sigue activo hasta terminar la lectura de hoy.")
    static let focusOpen = LText("Today's reading is done. Your apps are open.", "La lectura de hoy está hecha. Tus apps están abiertas.")
    static let focusFailDenied = LText("Lumen needs Screen Time access to keep apps closed. You can allow it whenever you are ready.", "Lumen necesita acceso a Tiempo de uso para mantener apps cerradas. Puedes permitirlo cuando quieras.")
    static let focusFailRestricted = LText("Screen Time is restricted on this iPhone, so apps cannot be shielded. Check Settings > Screen Time.", "Tiempo de uso está restringido en este iPhone, así que no se pueden bloquear apps. Revisa Ajustes > Tiempo de uso.")
    static let focusFailNotConfigured = LText("App blocking is not set up in this version yet. Everything else works as usual.", "El bloqueo de apps todavía no está activado en esta versión. Todo lo demás funciona como siempre.")
    static let focusFailUnavailable = LText("App blocking is not available here. It works on a real iPhone, not in the Simulator.", "El bloqueo de apps no está disponible aquí. Funciona en un iPhone real, no en el Simulador.")
    static let focusAllow = LText("Allow Screen Time access", "Permitir acceso a Tiempo de uso")
    static let focusPreviewShield = LText("Preview the shield screen", "Ver la pantalla de bloqueo")
    static let focusFootnote = LText("You are always in control. Turn Focus Mode off here at any time.", "Siempre tienes el control. Puedes apagar el Modo Enfoque aquí en cualquier momento.")
    static let shieldPreviewTag = LText("Shield preview", "Vista previa del bloqueo")
    static let shieldTitle = LText("%@ is waiting with today's verse", "%@ te espera con el versículo de hoy")
    static let shieldCTA = LText("Read to unlock", "Leer para desbloquear")

    // MARK: Settings
    static let settingsTitle = LText("Settings", "Ajustes")
    static let settingsSheep = LText("Your sheep", "Tu oveja")
    static let settingsReading = LText("Reading", "Lectura")
    static let settingsLanguage = LText("Language", "Idioma")
    static let settingsTranslation = LText("Translation", "Traducción")
    static let settingsDaily = LText("Daily time", "Tiempo diario")
    static let settingsReminder = LText("Reminder", "Recordatorio")
    static let settingsReminderNote = LText("One invitation a day. Never more, never a guilt trip.", "Una invitación al día. Nunca más, nunca con culpa.")
    static let settingsPremium = LText("Premium", "Premium")
    static let settingsPremiumActive = LText("Premium is active", "Premium está activo")
    static let settingsSeePlans = LText("See Premium plans", "Ver planes Premium")
    static let settingsAbout = LText("About %@", "Acerca de %@")
    static let aboutStudyAids = LText("Explanations and questions are study aids, not Scripture. They are written to stay faithful to the text and neutral between denominations.", "Las explicaciones y preguntas son ayudas de estudio, no la Escritura. Se escriben para ser fieles al texto y neutrales entre denominaciones.")
    static let aboutTranslations = LText("Bible text: King James Version, World English Bible and Reina-Valera 1909, all in the public domain.", "Texto bíblico: King James Version, World English Bible y Reina-Valera 1909, todas de dominio público.")
    static let aboutCare = LText("This app is a reading companion. It is not a substitute for pastoral, medical or mental-health care.", "Esta app es una compañera de lectura. No sustituye el cuidado pastoral, médico ni de salud mental.")
    static let devTitle = LText("Simulator tools", "Herramientas del simulador")
    static let devNextDay = LText("Jump to tomorrow", "Saltar a mañana")
    static let devSkipDay = LText("Skip a day (miss one)", "Saltar un día (perder uno)")
    static let devTogglePremium = LText("Toggle Premium", "Alternar Premium")
    static let devReset = LText("Reset everything", "Reiniciar todo")
    static let devNote = LText("For testing the streak loop. Day offset: %ld", "Para probar el ciclo de la luz. Días adelantados: %ld")

    // MARK: Notifications
    static let notificationBody = LText("%@ is waiting in the sun. Today: %@", "%@ te espera al sol. Hoy: %@")

    // MARK: Accessibility
    static let a11yStreak = LText("%ld days in the light", "%ld días en la luz")
    static let a11yStreakDim = LText("The light has dimmed. %ld days can still be recovered", "La luz ha bajado. Aún se pueden recuperar %ld días")
    static let a11yFreezes = LText("%ld rest days saved", "%ld días de descanso guardados")
    static let a11yCardProgress = LText("Card %ld of %ld", "Tarjeta %ld de %ld")
    static let a11yTapToUnderstand = LText("Opens a plain-language explanation", "Abre una explicación en lenguaje sencillo")
    static let a11ySwipeHint = LText("You can also swipe up", "También puedes deslizar hacia arriba")
    static let a11yXP = LText("%ld experience points earned", "%ld puntos de experiencia ganados")
    static let a11yNodeDone = LText("Completed. Opens a review", "Completado. Abre un repaso")
    static let a11yNodeCurrent = LText("Next reading", "Próxima lectura")
    static let a11yNodeLocked = LText("Not yet open", "Aún no disponible")
    static let a11yBookOpened = LText("read", "leído")
    static let a11yBookNotYet = LText("not yet read", "aún sin leer")
    static let a11yLeagueRow = LText("Place %ld, %@, %ld XP", "Puesto %ld, %@, %ld XP")
}
