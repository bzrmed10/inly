import Foundation

/// All translations (French, Arabic, Spanish). English is the key itself unless an entry has its own `en`.
/// Kept as JSON text so the compiler never has to type-check a huge literal.
enum Strings {
    static let table: [String: Entry] = {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: Entry].self, from: data) else { return [:] }
        return decoded
    }()

    private static let json = #"""
{
 "!": {
  "ar": "!",
  "es": "!",
  "fr": "!"
 },
 "\"Back in\" has to be after \"out\".": {
  "ar": "يجب أن تكون «الإعادة» بعد «الإخراج».",
  "es": "«Puestos» debe ser después de «quitados».",
  "fr": "« Remis » doit être après « retiré »."
 },
 "%@ earlier than planned (%d)": {
  "ar": "%@ أبكر من المخطط (%d)",
  "es": "%@ antes de lo previsto (%d)",
  "fr": "%@ plus tôt que prévu (%d)"
 },
 "%@ later than planned (%d)": {
  "ar": "%@ أبعد من المخطط (%d)",
  "es": "%@ después de lo previsto (%d)",
  "fr": "%@ plus tard que prévu (%d)"
 },
 "%@ left": {
  "ar": "متبقي %@",
  "es": "quedan %@",
  "fr": "%@ restant"
 },
 "%@ left today": {
  "ar": "متبقي اليوم %@",
  "es": "quedan %@ hoy",
  "fr": "%@ restant aujourd'hui"
 },
 "%@ of out-time left": {
  "ar": "متبقي %@ من وقت الإخراج",
  "es": "quedan %@ de tiempo fuera",
  "fr": "%@ de temps hors bouche restant"
 },
 "%@ to %@": {
  "ar": "من %@ إلى %@",
  "es": "del %@ al %@",
  "fr": "%@ au %@"
 },
 "%@ to go": {
  "ar": "متبقي %@",
  "es": "faltan %@",
  "fr": "%@ restantes"
 },
 "%@ worn today": {
  "ar": "%@ مرتدى اليوم",
  "es": "%@ puesto hoy",
  "fr": "%@ portées aujourd'hui"
 },
 "%@ · %@ out": {
  "ar": "%@ · %@ خارج الفم",
  "es": "%@ · %@ fuera",
  "fr": "%@ · %@ hors bouche"
 },
 "%@: %@ hours worn": {
  "ar": "%@: %@ ساعة مرتدى",
  "es": "%@: %@ horas puesto",
  "fr": "%@ : %@ heures portées"
 },
 "%@: no data": {
  "ar": "%@: لا توجد بيانات",
  "es": "%@: sin datos",
  "fr": "%@ : aucune donnée"
 },
 "%d done · avg %@ days": {
  "ar": "%d مكتملة · المتوسط %@ يوم",
  "es": "%d completados · media %@ días",
  "fr": "%d terminées · moy. %@ jours"
 },
 "%d hours": {
  "ar": "%d ساعة",
  "es": "%d horas",
  "fr": "%d heures"
 },
 "%d hours a day": {
  "ar": "%d ساعة يوميًا",
  "es": "%d horas al día",
  "fr": "%d heures par jour"
 },
 "%d of %d": {
  "ar": "%d من %d",
  "es": "%d de %d",
  "fr": "%d sur %d"
 },
 "%d percent": {
  "ar": "%d بالمئة",
  "es": "%d por ciento",
  "fr": "%d pour cent"
 },
 "+%@ over the plan": {
  "ar": "+%@ فوق الخطة",
  "es": "+%@ más de lo planeado",
  "fr": "+%@ au-delà du plan"
 },
 ", ": {
  "ar": "، ",
  "es": ", ",
  "fr": ", "
 },
 "10 minutes of out-time left": {
  "ar": "بقيت 10 دقائق من وقت الإخراج",
  "es": "Quedan 10 minutos fuera",
  "fr": "Plus que 10 minutes hors bouche"
 },
 "30 days": {
  "ar": "30 يومًا",
  "es": "30 días",
  "fr": "30 jours"
 },
 "7 days": {
  "ar": "7 أيام",
  "es": "7 días",
  "fr": "7 jours"
 },
 "A nudge before your out-time runs out and on tray-change day.": {
  "ar": "تنبيه قبل انتهاء وقت الإخراج وفي يوم تغيير الطقم.",
  "es": "Un aviso antes de que se acabe tu tiempo fuera y el día de cambio de alineador.",
  "fr": "Un rappel avant la fin de votre temps hors bouche et le jour du changement de gouttière."
 },
 "A nudge when you've been out for a while, with a Put back in button.": {
  "ar": "تنبيه عندما تطول مدة إخراج المقوّمات، مع زر لإعادتها.",
  "es": "Un aviso cuando llevas un rato sin ellos, con un botón para ponerlos.",
  "fr": "Un rappel quand vos aligneurs sont retirés depuis un moment, avec un bouton Remettre."
 },
 "ALIGNERS OUT · %@": {
  "ar": "المقوّمات خارج الفم · %@",
  "es": "ALINEADORES FUERA · %@",
  "fr": "ALIGNEURS RETIRÉS · %@"
 },
 "Add a missed break": {
  "ar": "إضافة استراحة منسية",
  "es": "Añadir una pausa olvidada",
  "fr": "Ajouter une pause oubliée"
 },
 "Add a photo of your teeth in this tray": {
  "ar": "أضف صورة لأسنانك مع هذا الطقم",
  "es": "Añade una foto de tus dientes con este alineador",
  "fr": "Ajoutez une photo de vos dents avec cette gouttière"
 },
 "Add a photo to at least two trays to compare them.": {
  "ar": "أضف صورة لطقمين على الأقل للمقارنة بينهما.",
  "es": "Añade una foto a al menos dos alineadores para compararlos.",
  "fr": "Ajoutez une photo à au moins deux gouttières pour les comparer."
 },
 "Add a widget and log with one tap. It works on your Home Screen, Lock Screen and Apple Watch.": {
  "ar": "أضف ويدجت وسجّل بلمسة واحدة. يعمل على الشاشة الرئيسية وشاشة القفل وApple Watch.",
  "es": "Añade un widget y registra con un toque. Funciona en la pantalla de inicio, la pantalla de bloqueo y el Apple Watch.",
  "fr": "Ajoutez un widget et enregistrez d'un seul toucher. Il fonctionne sur l'écran d'accueil, l'écran verrouillé et l'Apple Watch."
 },
 "Add days": {
  "ar": "إضافة أيام",
  "es": "Añadir días",
  "fr": "Ajouter des jours"
 },
 "Add note": {
  "ar": "إضافة ملاحظة",
  "es": "Añadir nota",
  "fr": "Ajouter une note"
 },
 "Add orthodontist visit": {
  "ar": "إضافة موعد طبيب التقويم",
  "es": "Añadir cita con el ortodoncista",
  "fr": "Ajouter un rendez-vous chez l'orthodontiste"
 },
 "Add the widget": {
  "ar": "أضف الويدجت",
  "es": "Añade el widget",
  "fr": "Ajouter le widget"
 },
 "Add your next appointment": {
  "ar": "أضف موعدك القادم",
  "es": "Añade tu próxima cita",
  "fr": "Ajoutez votre prochain rendez-vous"
 },
 "After": {
  "ar": "بعد",
  "es": "Después",
  "fr": "Après"
 },
 "Aligner wear report": {
  "ar": "تقرير ارتداء المقوّمات",
  "es": "Informe de uso de alineadores",
  "fr": "Rapport de port des aligneurs"
 },
 "Aligners IN": {
  "ar": "المقوّمات في الفم",
  "es": "Alineadores PUESTOS",
  "fr": "Aligneurs EN BOUCHE"
 },
 "Aligners OUT": {
  "ar": "المقوّمات خارج الفم",
  "es": "Alineadores FUERA",
  "fr": "Aligneurs RETIRÉS"
 },
 "Aligners back in": {
  "ar": "أُعيدت المقوّمات",
  "es": "Alineadores puestos",
  "fr": "Aligneurs remis"
 },
 "Aligners in · %@ out-time left": {
  "ar": "المقوّمات في الفم · متبقي %@ من وقت الإخراج",
  "es": "Alineadores puestos · quedan %@ fuera",
  "fr": "Aligneurs en bouche · %@ hors bouche restant"
 },
 "Aligners out": {
  "ar": "المقوّمات خارج الفم",
  "es": "Alineadores fuera",
  "fr": "Aligneurs retirés"
 },
 "All good": {
  "ar": "كل شيء بخير",
  "es": "Todo bien",
  "fr": "Tout va bien"
 },
 "Always on top": {
  "ar": "دائمًا في المقدمة",
  "es": "Siempre a la vista",
  "fr": "Toujours visible"
 },
 "Appointment at %@. Keep your aligners in until you arrive.": {
  "ar": "الموعد عند %@. أبقِ المقوّمات في فمك حتى تصل.",
  "es": "Cita a las %@. Mantén tus alineadores puestos hasta llegar.",
  "fr": "Rendez-vous à %@. Gardez vos aligneurs jusqu'à votre arrivée."
 },
 "Ask after %d min": {
  "ar": "اسأل بعد %d د",
  "es": "Preguntar tras %d min",
  "fr": "Demander après %d min"
 },
 "Attachment loose": {
  "ar": "الزر اللاصق مفكوك",
  "es": "Attach suelto",
  "fr": "Taquet décollé"
 },
 "Automatic backup": {
  "ar": "نسخ احتياطي تلقائي",
  "es": "Copia automática",
  "fr": "Sauvegarde automatique"
 },
 "Automatic backup is on.": {
  "ar": "النسخ الاحتياطي التلقائي مفعّل.",
  "es": "La copia automática está activada.",
  "fr": "La sauvegarde automatique est activée."
 },
 "Automatic backup · %@": {
  "ar": "نسخ احتياطي تلقائي · %@",
  "es": "Copia automática · %@",
  "fr": "Sauvegarde automatique · %@"
 },
 "Average wear: %@ hours a day over %d complete days": {
  "ar": "متوسط الارتداء: %@ ساعة يوميًا خلال %d يومًا كاملًا",
  "es": "Uso medio: %@ horas al día en %d días completos",
  "fr": "Port moyen : %@ heures par jour sur %d jours complets"
 },
 "Avg wear": {
  "ar": "متوسط الارتداء",
  "es": "Uso medio",
  "fr": "Port moy."
 },
 "Back": {
  "ar": "رجوع",
  "es": "Atrás",
  "fr": "Retour"
 },
 "Back in at": {
  "ar": "أُعيدت عند",
  "es": "Puestos a las",
  "fr": "Remis à"
 },
 "Back in by %@": {
  "ar": "أعدها قبل %@",
  "es": "Ponlos antes de las %@",
  "fr": "Remettre avant %@"
 },
 "Back up now": {
  "ar": "نسخ احتياطي الآن",
  "es": "Hacer copia ahora",
  "fr": "Sauvegarder maintenant"
 },
 "Backup": {
  "ar": "النسخ الاحتياطي",
  "es": "Copia de seguridad",
  "fr": "Sauvegarde"
 },
 "Backup restored.": {
  "ar": "تمت استعادة النسخة الاحتياطية.",
  "es": "Copia restaurada.",
  "fr": "Sauvegarde restaurée."
 },
 "Backup saved.": {
  "ar": "تم حفظ النسخة الاحتياطية.",
  "es": "Copia guardada.",
  "fr": "Sauvegarde enregistrée."
 },
 "Backups include your history, trays, photos, notes and settings.": {
  "ar": "تشمل النسخ الاحتياطية سجلك وأطقمك وصورك وملاحظاتك وإعداداتك.",
  "es": "Las copias incluyen tu historial, alineadores, fotos, notas y ajustes.",
  "fr": "Les sauvegardes incluent votre historique, vos gouttières, photos, notes et réglages."
 },
 "Before": {
  "ar": "قبل",
  "es": "Antes",
  "fr": "Avant"
 },
 "Before and after slider": {
  "ar": "شريط قبل وبعد",
  "es": "Control deslizante antes y después",
  "fr": "Curseur avant et après"
 },
 "Best streak": {
  "ar": "أفضل سلسلة",
  "es": "Mejor racha",
  "fr": "Meilleure série"
 },
 "Brushing": {
  "ar": "تنظيف الأسنان",
  "es": "Cepillado",
  "fr": "Brossage"
 },
 "CSV · per day": {
  "ar": "CSV · لكل يوم",
  "es": "CSV · por día",
  "fr": "CSV · par jour"
 },
 "Camera": {
  "ar": "الكاميرا",
  "es": "Cámara",
  "fr": "Appareil photo"
 },
 "Camera access is off": {
  "ar": "الوصول إلى الكاميرا متوقف",
  "es": "El acceso a la cámara está desactivado",
  "fr": "L'accès à l'appareil photo est désactivé"
 },
 "Cancel": {
  "ar": "إلغاء",
  "es": "Cancelar",
  "fr": "Annuler"
 },
 "Close": {
  "ar": "إغلاق",
  "es": "Cerrar",
  "fr": "Fermer"
 },
 "Compare": {
  "ar": "مقارنة",
  "es": "Comparar",
  "fr": "Comparer"
 },
 "Compare photos": {
  "ar": "مقارنة الصور",
  "es": "Comparar fotos",
  "fr": "Comparer les photos"
 },
 "Counting starts as out. Tap Put back in when they're in.": {
  "ar": "يبدأ العدّ كأنها خارج الفم. اضغط «إعادة» عندما تضعها.",
  "es": "El conteo empieza como fuera. Toca Poner cuando los tengas puestos.",
  "fr": "Le décompte démarre comme retiré. Touchez Remettre quand ils sont en bouche."
 },
 "Counting starts as worn.": {
  "ar": "يبدأ العدّ كأنها في الفم.",
  "es": "El conteo empieza como puesto.",
  "fr": "Le décompte démarre comme porté."
 },
 "Created with Inly on %@": {
  "ar": "أُنشئ بواسطة Inly في %@",
  "es": "Creado con Inly el %@",
  "fr": "Créé avec Inly le %@"
 },
 "Current streak: %@ · best: %@": {
  "ar": "السلسلة الحالية: %@ · الأفضل: %@",
  "es": "Racha actual: %@ · mejor: %@",
  "fr": "Série actuelle : %@ · meilleure : %@"
 },
 "Current tray": {
  "ar": "الطقم الحالي",
  "es": "Alineador actual",
  "fr": "Gouttière actuelle"
 },
 "Daily average": {
  "ar": "المتوسط اليومي",
  "es": "Media diaria",
  "fr": "Moyenne par jour"
 },
 "Daily goal": {
  "ar": "الهدف اليومي",
  "es": "Objetivo diario",
  "fr": "Objectif quotidien"
 },
 "Daily wear": {
  "ar": "الارتداء اليومي",
  "es": "Uso diario",
  "fr": "Port quotidien"
 },
 "Day": {
  "ar": "اليوم",
  "es": "Día",
  "fr": "Jour"
 },
 "Day %d of %d": {
  "ar": "اليوم %d من %d",
  "es": "Día %d de %d",
  "fr": "Jour %d sur %d"
 },
 "Day %d of %d · switch in %@": {
  "ar": "اليوم %d من %d · التغيير بعد %@",
  "es": "Día %d de %d · cambio en %@",
  "fr": "Jour %d sur %d · changement dans %@"
 },
 "Day %d of %d. Switch to tray %d in %@.": {
  "ar": "اليوم %d من %d. انتقل إلى الطقم %d بعد %@.",
  "es": "Día %d de %d. Cambia al alineador %d en %@.",
  "fr": "Jour %d sur %d. Passez à la gouttière %d dans %@."
 },
 "Day %d of %d. You're due to switch to tray %d today.": {
  "ar": "اليوم %d من %d. حان موعد الانتقال إلى الطقم %d اليوم.",
  "es": "Día %d de %d. Hoy te toca cambiar al alineador %d.",
  "fr": "Jour %d sur %d. Vous devez passer à la gouttière %d aujourd'hui."
 },
 "Day 1": {
  "ar": "اليوم 1",
  "es": "Día 1",
  "fr": "Jour 1"
 },
 "Days (plan)": {
  "ar": "الأيام (الخطة)",
  "es": "Días (plan)",
  "fr": "Jours (plan)"
 },
 "Days each": {
  "ar": "أيام لكل طقم",
  "es": "Días cada uno",
  "fr": "Jours chacune"
 },
 "Days on this tray": {
  "ar": "أيام هذا الطقم",
  "es": "Días con este alineador",
  "fr": "Jours avec cette gouttière"
 },
 "Default days per tray": {
  "ar": "الأيام الافتراضية لكل طقم",
  "es": "Días por alineador por defecto",
  "fr": "Jours par gouttière par défaut"
 },
 "Delete": {
  "ar": "حذف",
  "es": "Eliminar",
  "fr": "Supprimer"
 },
 "Delete note": {
  "ar": "حذف الملاحظة",
  "es": "Eliminar nota",
  "fr": "Supprimer la note"
 },
 "Delete this break": {
  "ar": "حذف هذه الاستراحة",
  "es": "Eliminar esta pausa",
  "fr": "Supprimer cette pause"
 },
 "Delete this break?": {
  "ar": "حذف هذه الاستراحة؟",
  "es": "¿Eliminar esta pausa?",
  "fr": "Supprimer cette pause ?"
 },
 "Done": {
  "ar": "تم",
  "es": "Listo",
  "fr": "OK"
 },
 "Drink": {
  "ar": "مشروب",
  "es": "Bebida",
  "fr": "Boisson"
 },
 "Edit break": {
  "ar": "تعديل الاستراحة",
  "es": "Editar pausa",
  "fr": "Modifier la pause"
 },
 "Edit orthodontist visit": {
  "ar": "تعديل موعد طبيب التقويم",
  "es": "Editar cita con el ortodoncista",
  "fr": "Modifier le rendez-vous chez l'orthodontiste"
 },
 "Edit this break": {
  "ar": "تعديل هذه الاستراحة",
  "es": "Editar esta pausa",
  "fr": "Modifier cette pause"
 },
 "Estimated finish %@": {
  "ar": "الانتهاء المتوقع: %@",
  "es": "Fin estimado: %@",
  "fr": "Fin estimée : %@"
 },
 "Everything": {
  "ar": "كل شيء",
  "es": "Todo",
  "fr": "Tout"
 },
 "Existing backup files stay where they are": {
  "ar": "تبقى ملفات النسخ الاحتياطي الحالية في مكانها",
  "es": "Los archivos de copia existentes se quedan donde están",
  "fr": "Les fichiers de sauvegarde existants restent à leur place"
 },
 "Extend by %@": {
  "ar": "تمديد %@",
  "es": "Ampliar %@",
  "fr": "Prolonger de %@"
 },
 "Extend plan": {
  "ar": "تمديد الخطة",
  "es": "Ampliar el plan",
  "fr": "Prolonger le plan"
 },
 "Extend tray %d": {
  "ar": "تمديد الطقم %d",
  "es": "Ampliar el alineador %d",
  "fr": "Prolonger la gouttière %d"
 },
 "Format": {
  "ar": "الصيغة",
  "es": "Formato",
  "fr": "Format"
 },
 "Get a nudge when your aligners have been out too long. Turn off what you don't need.": {
  "ar": "احصل على تنبيه عندما تطول مدة إخراج المقوّمات. أوقف ما لا تحتاجه.",
  "es": "Recibe un aviso cuando lleves demasiado tiempo sin los alineadores. Desactiva lo que no necesites.",
  "fr": "Recevez un rappel quand vos aligneurs sont retirés trop longtemps. Désactivez ce dont vous n'avez pas besoin."
 },
 "Get started": {
  "ar": "ابدأ",
  "es": "Empezar",
  "fr": "Commencer"
 },
 "Goal": {
  "ar": "الهدف",
  "es": "Objetivo",
  "fr": "Objectif"
 },
 "Goal %d": {
  "ar": "الهدف %d",
  "es": "Objetivo %d",
  "fr": "Objectif %d"
 },
 "Goal %d h a day": {
  "ar": "الهدف %d ساعة يوميًا",
  "es": "Objetivo %d h al día",
  "fr": "Objectif %d h par jour"
 },
 "Goal met": {
  "ar": "تحقق الهدف",
  "es": "Objetivo cumplido",
  "fr": "Objectif atteint"
 },
 "Goal reached on %d of %d days (%d%%)": {
  "ar": "تحقق الهدف في %d من %d يومًا (%d%%)",
  "es": "Objetivo cumplido %d de %d días (%d %%)",
  "fr": "Objectif atteint %d jours sur %d (%d %%)"
 },
 "Goal: %d hours a day": {
  "ar": "الهدف: %d ساعة يوميًا",
  "es": "Objetivo: %d horas al día",
  "fr": "Objectif : %d heures par jour"
 },
 "Good afternoon": {
  "ar": "مساء الخير",
  "es": "Buenas tardes",
  "fr": "Bon après-midi"
 },
 "Good evening": {
  "ar": "مساء الخير",
  "es": "Buenas noches",
  "fr": "Bonsoir"
 },
 "Good morning": {
  "ar": "صباح الخير",
  "es": "Buenos días",
  "fr": "Bonjour"
 },
 "History": {
  "ar": "السجل",
  "es": "Historial",
  "fr": "Historique"
 },
 "Hours a day": {
  "ar": "ساعات يوميًا",
  "es": "Horas al día",
  "fr": "Heures par jour"
 },
 "Hours worn per day over the last 7 days, goal %d hours": {
  "ar": "ساعات الارتداء يوميًا خلال آخر 7 أيام، الهدف %d ساعة",
  "es": "Horas de uso por día en los últimos 7 días, objetivo %d horas",
  "fr": "Heures portées par jour sur les 7 derniers jours, objectif %d heures"
 },
 "In": {
  "ar": "في الفم",
  "es": "Puestos",
  "fr": "En bouche"
 },
 "Inly %@ · Your data stays on your devices.": {
  "ar": "Inly %@ · تبقى بياناتك على أجهزتك.",
  "es": "Inly %@ · Tus datos se quedan en tus dispositivos.",
  "fr": "Inly %@ · Vos données restent sur vos appareils."
 },
 "Install the watch app": {
  "ar": "ثبّت تطبيق الساعة",
  "es": "Instala la app del reloj",
  "fr": "Installer l'app pour la montre"
 },
 "Language": {
  "ar": "اللغة",
  "es": "Idioma",
  "fr": "Langue"
 },
 "Last 7 days": {
  "ar": "آخر 7 أيام",
  "es": "Últimos 7 días",
  "fr": "7 derniers jours"
 },
 "Last backup %@": {
  "ar": "آخر نسخة احتياطية: %@",
  "es": "Última copia: %@",
  "fr": "Dernière sauvegarde : %@"
 },
 "Last photo: off": {
  "ar": "الصورة السابقة: متوقفة",
  "es": "Foto anterior: no",
  "fr": "Dernière photo : off"
 },
 "Last photo: on": {
  "ar": "الصورة السابقة: مفعّلة",
  "es": "Foto anterior: sí",
  "fr": "Dernière photo : on"
 },
 "Left": {
  "ar": "المتبقي",
  "es": "Queda",
  "fr": "Reste"
 },
 "Lets you pick your current tray and day again. Your wear history stays.": {
  "ar": "تتيح لك اختيار طقمك الحالي ويومك من جديد. يبقى سجل ارتدائك كما هو.",
  "es": "Te permite elegir de nuevo tu alineador y día actuales. Tu historial de uso se conserva.",
  "fr": "Vous permet de choisir à nouveau votre gouttière et votre jour actuels. Votre historique de port est conservé."
 },
 "Library": {
  "ar": "الاستوديو",
  "es": "Fototeca",
  "fr": "Photothèque"
 },
 "Lisp": {
  "ar": "لثغة",
  "es": "Ceceo",
  "fr": "Zézaiement"
 },
 "Meal": {
  "ar": "وجبة",
  "es": "Comida",
  "fr": "Repas"
 },
 "Meet Inly": {
  "ar": "تعرّف على Inly",
  "es": "Conoce Inly",
  "fr": "Voici Inly"
 },
 "Missed": {
  "ar": "فائت",
  "es": "Fallido",
  "fr": "Manqué"
 },
 "Most orthodontists ask for 20 to 22 hours a day. Use the number your orthodontist gave you.": {
  "ar": "يطلب معظم أطباء التقويم من 20 إلى 22 ساعة يوميًا. استخدم الرقم الذي أعطاك إياه طبيبك.",
  "es": "La mayoría de los ortodoncistas piden de 20 a 22 horas al día. Usa el número que te dio el tuyo.",
  "fr": "La plupart des orthodontistes demandent 20 à 22 heures par jour. Utilisez le nombre donné par votre orthodontiste."
 },
 "My aligners are in right now": {
  "ar": "المقوّمات في فمي الآن",
  "es": "Tengo los alineadores puestos ahora",
  "fr": "Mes aligneurs sont en bouche"
 },
 "Never forget them": {
  "ar": "لن تنساها أبدًا",
  "es": "Que no se te olviden",
  "fr": "Ne les oubliez jamais"
 },
 "New plan: %@. Switch on %@.": {
  "ar": "الخطة الجديدة: %@. التغيير في %@.",
  "es": "Nuevo plan: %@. Cambio el %@.",
  "fr": "Nouveau plan : %@. Changement le %@."
 },
 "Next": {
  "ar": "التالي",
  "es": "Siguiente",
  "fr": "Suivant"
 },
 "Next appointment: %@": {
  "ar": "الموعد القادم: %@",
  "es": "Próxima cita: %@",
  "fr": "Prochain rendez-vous : %@"
 },
 "Next month": {
  "ar": "الشهر التالي",
  "es": "Mes siguiente",
  "fr": "Mois suivant"
 },
 "Next orthodontist visit": {
  "ar": "موعد طبيب التقويم القادم",
  "es": "Próxima visita al ortodoncista",
  "fr": "Prochain rendez-vous chez l'orthodontiste"
 },
 "No breaks recorded this day.": {
  "ar": "لا توجد استراحات مسجلة في هذا اليوم.",
  "es": "No hay pausas registradas este día.",
  "fr": "Aucune pause enregistrée ce jour-là."
 },
 "No breaks yet": {
  "ar": "لا استراحات بعد",
  "es": "Aún no hay pausas",
  "fr": "Aucune pause pour l'instant"
 },
 "No notes yet. Tap a suggestion above or write your own.": {
  "ar": "لا توجد ملاحظات بعد. اضغط على اقتراح أعلاه أو اكتب ملاحظتك.",
  "es": "Aún no hay notas. Toca una sugerencia de arriba o escribe la tuya.",
  "fr": "Aucune note pour l'instant. Touchez une suggestion ci-dessus ou écrivez la vôtre."
 },
 "No tray yet": {
  "ar": "لا يوجد طقم بعد",
  "es": "Aún no hay alineador",
  "fr": "Pas encore de gouttière"
 },
 "Not enough complete days yet.": {
  "ar": "لا توجد أيام كاملة كافية بعد.",
  "es": "Aún no hay suficientes días completos.",
  "fr": "Pas encore assez de jours complets."
 },
 "Notes": {
  "ar": "الملاحظات",
  "es": "Notas",
  "fr": "Notes"
 },
 "OK": {
  "ar": "حسنًا",
  "es": "OK",
  "fr": "OK"
 },
 "OUT": {
  "ar": "خارج الفم",
  "es": "FUERA",
  "fr": "RETIRÉ"
 },
 "OUT FOR": {
  "ar": "خارج الفم منذ",
  "es": "FUERA HACE",
  "fr": "RETIRÉ DEPUIS"
 },
 "Of": {
  "ar": "من",
  "es": "De",
  "fr": "Sur"
 },
 "Off": {
  "ar": "متوقف",
  "es": "Desactivado",
  "fr": "Désactivé"
 },
 "One less": {
  "ar": "واحد أقل",
  "es": "Uno menos",
  "fr": "Un de moins"
 },
 "One more": {
  "ar": "واحد أكثر",
  "es": "Uno más",
  "fr": "Un de plus"
 },
 "Open Inly": {
  "ar": "افتح Inly",
  "es": "Abrir Inly",
  "fr": "Ouvrir Inly"
 },
 "Open Inly on your iPhone once to connect.": {
  "ar": "افتح Inly على iPhone مرة واحدة للاتصال.",
  "es": "Abre Inly una vez en tu iPhone para conectar.",
  "fr": "Ouvrez Inly une fois sur votre iPhone pour vous connecter."
 },
 "Open Settings": {
  "ar": "افتح الإعدادات",
  "es": "Abrir Ajustes",
  "fr": "Ouvrir les réglages"
 },
 "Open the Watch app on your iPhone and install Inly.": {
  "ar": "افتح تطبيق Watch على iPhone وثبّت Inly.",
  "es": "Abre la app Watch en tu iPhone e instala Inly.",
  "fr": "Ouvrez l'app Watch sur votre iPhone et installez Inly."
 },
 "Opens your trays": {
  "ar": "يفتح أطقمك",
  "es": "Abre tus alineadores",
  "fr": "Ouvre vos gouttières"
 },
 "Orthodontist today": {
  "ar": "طبيب التقويم اليوم",
  "es": "Ortodoncista hoy",
  "fr": "Orthodontiste aujourd'hui"
 },
 "Orthodontist tomorrow": {
  "ar": "طبيب التقويم غدًا",
  "es": "Ortodoncista mañana",
  "fr": "Orthodontiste demain"
 },
 "Orthodontist visit": {
  "ar": "موعد طبيب التقويم",
  "es": "Cita con el ortodoncista",
  "fr": "Rendez-vous orthodontiste"
 },
 "Other": {
  "ar": "أخرى",
  "es": "Otro",
  "fr": "Autre"
 },
 "Out": {
  "ar": "خارج",
  "es": "Fuera",
  "fr": "Retiré"
 },
 "Out at": {
  "ar": "أُخرجت عند",
  "es": "Quitados a las",
  "fr": "Retiré à"
 },
 "Out periods": {
  "ar": "فترات الإخراج",
  "es": "Periodos fuera",
  "fr": "Périodes hors bouche"
 },
 "Out-time and tray reminders": {
  "ar": "تذكيرات وقت الإخراج وتغيير الطقم",
  "es": "Avisos de tiempo fuera y cambio de alineador",
  "fr": "Rappels hors bouche et changement de gouttière"
 },
 "Over budget": {
  "ar": "تجاوزت الحد",
  "es": "Presupuesto superado",
  "fr": "Budget dépassé"
 },
 "Over today's budget": {
  "ar": "تجاوزت حد اليوم",
  "es": "Presupuesto de hoy superado",
  "fr": "Budget du jour dépassé"
 },
 "PDF report": {
  "ar": "تقرير PDF",
  "es": "Informe PDF",
  "fr": "Rapport PDF"
 },
 "Patient": {
  "ar": "المريض",
  "es": "Paciente",
  "fr": "Patient"
 },
 "Period": {
  "ar": "الفترة",
  "es": "Periodo",
  "fr": "Période"
 },
 "Phone language": {
  "ar": "لغة الهاتف",
  "es": "Idioma del teléfono",
  "fr": "Langue du téléphone"
 },
 "Photo & notes": {
  "ar": "صورة وملاحظات",
  "es": "Foto y notas",
  "fr": "Photo et notes"
 },
 "Photo & notes ✓": {
  "ar": "صورة وملاحظات ✓",
  "es": "Foto y notas ✓",
  "fr": "Photo et notes ✓"
 },
 "Pick an iCloud Drive folder once; Inly keeps it up to date": {
  "ar": "اختر مجلدًا في iCloud Drive مرة واحدة وسيُبقيه Inly محدّثًا",
  "es": "Elige una carpeta de iCloud Drive una vez; Inly la mantiene al día",
  "fr": "Choisissez un dossier iCloud Drive une fois ; Inly le tient à jour"
 },
 "Planned: %@. Use this when your orthodontist asks for more time on this tray.": {
  "ar": "المخطط: %@. استخدم هذا عندما يطلب طبيبك وقتًا أطول لهذا الطقم.",
  "es": "Previsto: %@. Úsalo cuando tu ortodoncista pida más tiempo con este alineador.",
  "fr": "Prévu : %@. Utilisez ceci quand votre orthodontiste demande plus de temps avec cette gouttière."
 },
 "Pressure": {
  "ar": "ضغط",
  "es": "Presión",
  "fr": "Pression"
 },
 "Previous month": {
  "ar": "الشهر السابق",
  "es": "Mes anterior",
  "fr": "Mois précédent"
 },
 "Profile": {
  "ar": "الملف الشخصي",
  "es": "Perfil",
  "fr": "Profil"
 },
 "Progress photo": {
  "ar": "صورة التقدم",
  "es": "Foto de progreso",
  "fr": "Photo de progression"
 },
 "Progress photo for tray %d": {
  "ar": "صورة تقدم الطقم %d",
  "es": "Foto de progreso del alineador %d",
  "fr": "Photo de progression de la gouttière %d"
 },
 "Put back in": {
  "ar": "إعادة",
  "es": "Poner",
  "fr": "Remettre"
 },
 "Put it in": {
  "ar": "وقت الإعادة",
  "es": "Puestos",
  "fr": "Remise en bouche"
 },
 "Put your aligners back in": {
  "ar": "أعد المقوّمات إلى فمك",
  "es": "Ponte los alineadores",
  "fr": "Remettez vos aligneurs"
 },
 "Records that your aligners are back in": {
  "ar": "يسجّل أن المقوّمات عادت إلى الفم",
  "es": "Registra que te has puesto los alineadores",
  "fr": "Enregistre que vos aligneurs sont remis"
 },
 "Redo first-time setup": {
  "ar": "إعادة الإعداد الأولي",
  "es": "Repetir la configuración inicial",
  "fr": "Refaire la configuration initiale"
 },
 "Redo setup": {
  "ar": "إعادة الإعداد",
  "es": "Repetir configuración",
  "fr": "Refaire la configuration"
 },
 "Redo setup?": {
  "ar": "إعادة الإعداد؟",
  "es": "¿Repetir la configuración?",
  "fr": "Refaire la configuration ?"
 },
 "Reminders": {
  "ar": "التذكيرات",
  "es": "Recordatorios",
  "fr": "Rappels"
 },
 "Remove photo": {
  "ar": "حذف الصورة",
  "es": "Eliminar foto",
  "fr": "Supprimer la photo"
 },
 "Remove visit": {
  "ar": "حذف الموعد",
  "es": "Eliminar cita",
  "fr": "Supprimer le rendez-vous"
 },
 "Replace everything with this backup?": {
  "ar": "استبدال كل شيء بهذه النسخة؟",
  "es": "¿Reemplazar todo con esta copia?",
  "fr": "Tout remplacer par cette sauvegarde ?"
 },
 "Replaces everything in Inly with a backup file": {
  "ar": "يستبدل كل ما في Inly بملف نسخة احتياطية",
  "es": "Reemplaza todo en Inly con un archivo de copia",
  "fr": "Remplace tout dans Inly par un fichier de sauvegarde"
 },
 "Restore": {
  "ar": "استعادة",
  "es": "Restaurar",
  "fr": "Restaurer"
 },
 "Restore from backup": {
  "ar": "استعادة من نسخة احتياطية",
  "es": "Restaurar desde copia",
  "fr": "Restaurer une sauvegarde"
 },
 "Retake": {
  "ar": "إعادة الالتقاط",
  "es": "Repetir",
  "fr": "Reprendre"
 },
 "Right on your Home Screen": {
  "ar": "مباشرة على شاشتك الرئيسية",
  "es": "Directo en tu pantalla de inicio",
  "fr": "Directement sur votre écran d'accueil"
 },
 "Save": {
  "ar": "حفظ",
  "es": "Guardar",
  "fr": "Enregistrer"
 },
 "Save a file to iCloud Drive or Files": {
  "ar": "احفظ ملفًا في iCloud Drive أو الملفات",
  "es": "Guarda un archivo en iCloud Drive o Archivos",
  "fr": "Enregistrer un fichier dans iCloud Drive ou Fichiers"
 },
 "Save visit": {
  "ar": "حفظ الموعد",
  "es": "Guardar cita",
  "fr": "Enregistrer le rendez-vous"
 },
 "See how your smile has moved": {
  "ar": "شاهد كيف تحرّكت ابتسامتك",
  "es": "Mira cómo se ha movido tu sonrisa",
  "fr": "Voyez comment votre sourire a bougé"
 },
 "Set up your tray": {
  "ar": "اضبط طقمك",
  "es": "Configura tu alineador",
  "fr": "Configurez votre gouttière"
 },
 "Settings": {
  "ar": "الإعدادات",
  "es": "Ajustes",
  "fr": "Réglages"
 },
 "Settings, Action Button, Shortcut, then choose Take out or Put back in.": {
  "ar": "الإعدادات، زر الإجراء، الاختصار، ثم اختر «إخراج» أو «إعادة».",
  "es": "Ajustes, botón de acción, Atajo, y elige Quitar o Poner.",
  "fr": "Réglages, bouton Action, Raccourci, puis choisissez Retirer ou Remettre."
 },
 "Setup": {
  "ar": "الإعداد",
  "es": "Configuración",
  "fr": "Configuration"
 },
 "Share %@": {
  "ar": "مشاركة %@",
  "es": "Compartir %@",
  "fr": "Partager en %@"
 },
 "Share with your orthodontist": {
  "ar": "شارك مع طبيب التقويم",
  "es": "Compartir con tu ortodoncista",
  "fr": "Partager avec votre orthodontiste"
 },
 "Slider": {
  "ar": "شريط",
  "es": "Deslizador",
  "fr": "Curseur"
 },
 "Smile and line your teeth up with the guide": {
  "ar": "ابتسم وطابق أسنانك مع الدليل",
  "es": "Sonríe y alinea tus dientes con la guía",
  "fr": "Souriez et alignez vos dents sur le guide"
 },
 "So we start counting from the right tray and the right day.": {
  "ar": "لنبدأ العدّ من الطقم الصحيح واليوم الصحيح.",
  "es": "Para empezar a contar desde el alineador y el día correctos.",
  "fr": "Pour compter à partir de la bonne gouttière et du bon jour."
 },
 "Sore teeth": {
  "ar": "ألم في الأسنان",
  "es": "Dientes doloridos",
  "fr": "Dents sensibles"
 },
 "Stacked": {
  "ar": "متراكب",
  "es": "Apilado",
  "fr": "Empilé"
 },
 "Start a tray to track how many days you stay on it.": {
  "ar": "ابدأ طقمًا لتتابع عدد الأيام التي تقضيها معه.",
  "es": "Empieza un alineador para ver cuántos días lo llevas.",
  "fr": "Démarrez une gouttière pour suivre le nombre de jours passés avec elle."
 },
 "Start tray %d": {
  "ar": "بدء الطقم %d",
  "es": "Empezar alineador %d",
  "fr": "Démarrer la gouttière %d"
 },
 "Start tray %d?": {
  "ar": "بدء الطقم %d؟",
  "es": "¿Empezar el alineador %d?",
  "fr": "Démarrer la gouttière %d ?"
 },
 "Started": {
  "ar": "البداية",
  "es": "Inicio",
  "fr": "Début"
 },
 "Started this tray": {
  "ar": "بدأت هذا الطقم في",
  "es": "Empecé este alineador el",
  "fr": "Gouttière commencée le"
 },
 "Starts timing how long your aligners are out": {
  "ar": "يبدأ حساب مدة إخراج المقوّمات",
  "es": "Empieza a medir cuánto tiempo llevas sin los alineadores",
  "fr": "Commence à chronométrer la durée hors bouche"
 },
 "Step %d of %d": {
  "ar": "الخطوة %d من %d",
  "es": "Paso %d de %d",
  "fr": "Étape %d sur %d"
 },
 "Still out. Put your aligners back in from Today to finish this break.": {
  "ar": "ما زالت خارج الفم. أعدها من «اليوم» لإنهاء هذه الاستراحة.",
  "es": "Siguen fuera. Ponlos desde Hoy para terminar esta pausa.",
  "fr": "Toujours retirés. Remettez vos aligneurs depuis Aujourd'hui pour terminer cette pause."
 },
 "Still out. Time to put them back?": {
  "ar": "ما زالت خارجًا. حان وقت إعادتها؟",
  "es": "Siguen fuera. ¿Es hora de ponerlos?",
  "fr": "Toujours retirés. C'est l'heure de les remettre ?"
 },
 "Still out?": {
  "ar": "ما زالت خارجًا؟",
  "es": "¿Siguen fuera?",
  "fr": "Toujours retirés ?"
 },
 "Still out? reminders": {
  "ar": "تذكيرات «ما زالت خارجًا؟»",
  "es": "Avisos de «¿Siguen fuera?»",
  "fr": "Rappels « Toujours retirés ? »"
 },
 "Streak": {
  "ar": "السلسلة",
  "es": "Racha",
  "fr": "Série"
 },
 "Style": {
  "ar": "النمط",
  "es": "Estilo",
  "fr": "Style"
 },
 "Summary": {
  "ar": "الملخص",
  "es": "Resumen",
  "fr": "Résumé"
 },
 "Switch camera": {
  "ar": "تبديل الكاميرا",
  "es": "Cambiar cámara",
  "fr": "Changer de caméra"
 },
 "Switch day": {
  "ar": "يوم التغيير",
  "es": "Día de cambio",
  "fr": "Jour de changement"
 },
 "Switch on": {
  "ar": "التغيير في",
  "es": "Cambio el",
  "fr": "Changement le"
 },
 "Switch reminder %@": {
  "ar": "تذكير التغيير: %@",
  "es": "Aviso de cambio: %@",
  "fr": "Rappel de changement : %@"
 },
 "Switch to tray %d today": {
  "ar": "انتقل إلى الطقم %d اليوم",
  "es": "Cambia hoy al alineador %d",
  "fr": "Passez à la gouttière %d aujourd'hui"
 },
 "Switched": {
  "ar": "تم التغيير",
  "es": "Cambiado",
  "fr": "Changée"
 },
 "Take out": {
  "ar": "إخراج",
  "es": "Quitar",
  "fr": "Retirer"
 },
 "Take photo": {
  "ar": "التقاط صورة",
  "es": "Hacer foto",
  "fr": "Prendre la photo"
 },
 "That leaves %d hours a day out of your mouth.": {
  "ar": "يترك ذلك %d ساعة يوميًا خارج فمك.",
  "es": "Eso deja %d horas al día fuera de la boca.",
  "fr": "Cela laisse %d heures par jour hors de la bouche."
 },
 "That overlaps another break.": {
  "ar": "هذا يتداخل مع استراحة أخرى.",
  "es": "Esto se solapa con otra pausa.",
  "fr": "Cela chevauche une autre pause."
 },
 "That's %@ over the plan, shown as +%d until you start tray %d.": {
  "ar": "هذا يتجاوز الخطة بـ %@، ويظهر كـ +%d حتى تبدأ الطقم %d.",
  "es": "Son %@ más de lo previsto, se muestra +%d hasta que empieces el alineador %d.",
  "fr": "Cela fait %@ de plus que prévu, affiché +%d jusqu'à ce que vous démarriez la gouttière %d."
 },
 "The calm way to track your aligners. One tap out, one tap back in.": {
  "ar": "الطريقة الهادئة لتتبع مقوّماتك. لمسة للإخراج ولمسة للإعادة.",
  "es": "La forma tranquila de seguir tus alineadores. Un toque para quitarlos, otro para ponerlos.",
  "fr": "La façon sereine de suivre vos aligneurs. Un toucher pour retirer, un toucher pour remettre."
 },
 "This backup was made by a newer version of Inly. Update the app first.": {
  "ar": "أُنشئت هذه النسخة بإصدار أحدث من Inly. حدّث التطبيق أولًا.",
  "es": "Esta copia la creó una versión más nueva de Inly. Actualiza la app primero.",
  "fr": "Cette sauvegarde a été créée par une version plus récente d'Inly. Mettez d'abord l'app à jour."
 },
 "This file isn't an Inly backup.": {
  "ar": "هذا الملف ليس نسخة احتياطية من Inly.",
  "es": "Este archivo no es una copia de Inly.",
  "fr": "Ce fichier n'est pas une sauvegarde Inly."
 },
 "Tight fit": {
  "ar": "ضيق",
  "es": "Muy ajustado",
  "fr": "Serrage"
 },
 "Time for tray %d": {
  "ar": "حان وقت الطقم %d",
  "es": "Es hora del alineador %d",
  "fr": "C'est l'heure de la gouttière %d"
 },
 "Time to wrap up and put your aligners back in.": {
  "ar": "حان وقت الانتهاء وإعادة المقوّمات إلى فمك.",
  "es": "Es hora de terminar y ponerte los alineadores.",
  "fr": "Il est temps de finir et de remettre vos aligneurs."
 },
 "Timer off": {
  "ar": "المؤقت متوقف",
  "es": "Temporizador apagado",
  "fr": "Minuteur désactivé"
 },
 "Timer on": {
  "ar": "المؤقت مفعّل",
  "es": "Temporizador activado",
  "fr": "Minuteur activé"
 },
 "Today": {
  "ar": "اليوم",
  "es": "Hoy",
  "fr": "Aujourd'hui"
 },
 "Today's out-time budget is used up.": {
  "ar": "انتهى حد وقت الإخراج لهذا اليوم.",
  "es": "Se acabó tu tiempo fuera de hoy.",
  "fr": "Votre budget de temps hors bouche du jour est épuisé."
 },
 "Today's timeline": {
  "ar": "جدول اليوم",
  "es": "Cronología de hoy",
  "fr": "Chronologie du jour"
 },
 "Touch and hold your Home Screen, tap +, then pick Inly.": {
  "ar": "اضغط مطولًا على الشاشة الرئيسية، ثم +، ثم اختر Inly.",
  "es": "Mantén pulsada la pantalla de inicio, toca + y elige Inly.",
  "fr": "Maintenez l'écran d'accueil, touchez +, puis choisissez Inly."
 },
 "Tray": {
  "ar": "الطقم",
  "es": "Alineador",
  "fr": "Gouttière"
 },
 "Tray %d": {
  "ar": "الطقم %d",
  "es": "Alineador %d",
  "fr": "Gouttière %d"
 },
 "Tray %d deleted": {
  "ar": "حُذف الطقم %d",
  "es": "Alineador %d eliminado",
  "fr": "Gouttière %d supprimée"
 },
 "Tray %d has had its %d days. Switch when you're ready, then log it in Inly.": {
  "ar": "أكمل الطقم %d أيامه الـ %d. بدّل عندما تكون جاهزًا ثم سجّل ذلك في Inly.",
  "es": "El alineador %d ya cumplió sus %d días. Cámbialo cuando quieras y regístralo en Inly.",
  "fr": "La gouttière %d a eu ses %d jours. Changez quand vous êtes prêt, puis notez-le dans Inly."
 },
 "Tray %d of %d": {
  "ar": "الطقم %d من %d",
  "es": "Alineador %d de %d",
  "fr": "Gouttière %d sur %d"
 },
 "Tray %d started": {
  "ar": "بدأ الطقم %d",
  "es": "Alineador %d iniciado",
  "fr": "Gouttière %d démarrée"
 },
 "Tray %d to tray %d · %@ apart": {
  "ar": "من الطقم %d إلى الطقم %d · بفارق %@",
  "es": "Del alineador %d al %d · %@ de diferencia",
  "fr": "Gouttière %d à gouttière %d · %@ d'écart"
 },
 "Tray %d will be saved with %@.": {
  "ar": "سيُحفظ الطقم %d بمدة %@.",
  "es": "El alineador %d se guardará con %@.",
  "fr": "La gouttière %d sera enregistrée avec %@."
 },
 "Tray %d · %@ – %@": {
  "ar": "الطقم %d · %@ – %@",
  "es": "Alineador %d · %@ – %@",
  "fr": "Gouttière %d · %@ – %@"
 },
 "Tray %d · Day %d of %d": {
  "ar": "الطقم %d · اليوم %d من %d",
  "es": "Alineador %d · Día %d de %d",
  "fr": "Gouttière %d · Jour %d sur %d"
 },
 "Tray history": {
  "ar": "سجل الأطقم",
  "es": "Historial de alineadores",
  "fr": "Historique des gouttières"
 },
 "Tray started": {
  "ar": "بدء طقم",
  "es": "Alineador iniciado",
  "fr": "Gouttière démarrée"
 },
 "Trays": {
  "ar": "الأطقم",
  "es": "Alineadores",
  "fr": "Gouttières"
 },
 "Trays in your treatment": {
  "ar": "الأطقم في علاجك",
  "es": "Alineadores en tu tratamiento",
  "fr": "Gouttières dans votre traitement"
 },
 "Treatment · %@": {
  "ar": "العلاج · %@",
  "es": "Tratamiento · %@",
  "fr": "Traitement · %@"
 },
 "Turn it on in Settings to take progress photos.": {
  "ar": "فعّلها من الإعدادات لالتقاط صور التقدم.",
  "es": "Actívalo en Ajustes para hacer fotos de progreso.",
  "fr": "Activez-le dans les réglages pour prendre des photos de progression."
 },
 "Turn off automatic backup": {
  "ar": "إيقاف النسخ الاحتياطي التلقائي",
  "es": "Desactivar la copia automática",
  "fr": "Désactiver la sauvegarde automatique"
 },
 "Two quick things make Inly even better.": {
  "ar": "أمران سريعان يجعلان Inly أفضل.",
  "es": "Dos cosas rápidas mejoran aún más Inly.",
  "fr": "Deux petites choses rendent Inly encore meilleur."
 },
 "Undo": {
  "ar": "تراجع",
  "es": "Deshacer",
  "fr": "Annuler"
 },
 "Use photo": {
  "ar": "استخدام الصورة",
  "es": "Usar foto",
  "fr": "Utiliser la photo"
 },
 "Use the Action Button": {
  "ar": "استخدم زر الإجراء",
  "es": "Usa el botón de acción",
  "fr": "Utilisez le bouton Action"
 },
 "Visit": {
  "ar": "الموعد",
  "es": "Cita",
  "fr": "Rendez-vous"
 },
 "WORN": {
  "ar": "مرتدى",
  "es": "PUESTO",
  "fr": "PORTÉ"
 },
 "WORN TODAY": {
  "ar": "مرتدى اليوم",
  "es": "PUESTO HOY",
  "fr": "PORTÉ AUJOURD'HUI"
 },
 "Waiting for first backup": {
  "ar": "بانتظار أول نسخة احتياطية",
  "es": "Esperando la primera copia",
  "fr": "En attente de la première sauvegarde"
 },
 "We'll remind you the evening before and the morning of.": {
  "ar": "سنذكّرك مساء اليوم السابق وصباح يوم الموعد.",
  "es": "Te avisaremos la tarde anterior y la mañana del día.",
  "fr": "Nous vous rappellerons la veille au soir et le matin même."
 },
 "We'll remind you to switch on %@.": {
  "ar": "سنذكّرك بالتغيير في %@.",
  "es": "Te avisaremos para cambiar el %@.",
  "fr": "Nous vous rappellerons de changer le %@."
 },
 "We'll use it to say hello.": {
  "ar": "سنستخدمه لنلقي عليك التحية.",
  "es": "Lo usaremos para saludarte.",
  "fr": "Nous l'utiliserons pour vous dire bonjour."
 },
 "Wear time, trays and notes in one file you can send by email or message.": {
  "ar": "وقت الارتداء والأطقم والملاحظات في ملف واحد يمكنك إرساله بالبريد أو برسالة.",
  "es": "Tiempo de uso, alineadores y notas en un archivo que puedes enviar por correo o mensaje.",
  "fr": "Temps de port, gouttières et notes dans un seul fichier à envoyer par e-mail ou message."
 },
 "Wear times are recorded by the patient in the Inly app and are not a medical record.": {
  "ar": "يسجّل المريض أوقات الارتداء في تطبيق Inly وهي ليست سجلًا طبيًا.",
  "es": "Los tiempos los registra el paciente en la app Inly y no son un registro médico.",
  "fr": "Les temps de port sont saisis par le patient dans l'app Inly et ne constituent pas un dossier médical."
 },
 "Wear your aligners": {
  "ar": "ارتدِ مقوّماتك",
  "es": "Usa tus alineadores",
  "fr": "Portez vos aligneurs"
 },
 "What should we call you?": {
  "ar": "بماذا نناديك؟",
  "es": "¿Cómo quieres que te llamemos?",
  "fr": "Comment devons-nous vous appeler ?"
 },
 "Which tray are you on?": {
  "ar": "في أي طقم أنت؟",
  "es": "¿En qué alineador estás?",
  "fr": "Sur quelle gouttière êtes-vous ?"
 },
 "Worn": {
  "ar": "مرتدى",
  "es": "Puesto",
  "fr": "Porté"
 },
 "Worn today": {
  "ar": "مرتدى اليوم",
  "es": "Puesto hoy",
  "fr": "Porté aujourd'hui"
 },
 "Write a note": {
  "ar": "اكتب ملاحظة",
  "es": "Escribe una nota",
  "fr": "Écrire une note"
 },
 "Yesterday": {
  "ar": "أمس",
  "es": "Ayer",
  "fr": "Hier"
 },
 "You can't log a break in the future.": {
  "ar": "لا يمكنك تسجيل استراحة في المستقبل.",
  "es": "No puedes registrar una pausa en el futuro.",
  "fr": "Vous ne pouvez pas enregistrer une pause dans le futur."
 },
 "You're all set": {
  "ar": "كل شيء جاهز",
  "es": "Todo listo",
  "fr": "Tout est prêt"
 },
 "You're all set, %@": {
  "ar": "كل شيء جاهز، %@",
  "es": "Todo listo, %@",
  "fr": "Tout est prêt, %@"
 },
 "Your aligners (%@) have been out for %d minutes.": {
  "ar": "المقوّمات (%@) خارج الفم منذ %d دقيقة.",
  "es": "Tus alineadores (%@) llevan fuera %d minutos.",
  "fr": "Vos aligneurs (%@) sont retirés depuis %d minutes."
 },
 "Your aligners have been out for %d minutes.": {
  "ar": "المقوّمات خارج الفم منذ %d دقيقة.",
  "es": "Tus alineadores llevan fuera %d minutos.",
  "fr": "Vos aligneurs sont retirés depuis %d minutes."
 },
 "Your aligners have been out for 45 minutes.": {
  "ar": "المقوّمات خارج الفم منذ 45 دقيقة.",
  "es": "Tus alineadores llevan fuera 45 minutos.",
  "fr": "Vos aligneurs sont retirés depuis 45 minutes."
 },
 "Your appointment is at %@. Bring your current and previous trays.": {
  "ar": "موعدك عند %@. أحضر طقمك الحالي والسابق.",
  "es": "Tu cita es a las %@. Lleva tu alineador actual y el anterior.",
  "fr": "Votre rendez-vous est à %@. Apportez vos gouttières actuelle et précédente."
 },
 "Your current history, trays, photos and notes are replaced.": {
  "ar": "سيتم استبدال سجلك وأطقمك وصورك وملاحظاتك الحالية.",
  "es": "Se reemplazan tu historial, alineadores, fotos y notas actuales.",
  "fr": "Votre historique, vos gouttières, photos et notes actuels sont remplacés."
 },
 "Your current tray is replaced by the one you pick. Wear history is kept.": {
  "ar": "يُستبدل طقمك الحالي بالذي تختاره. يبقى سجل الارتداء.",
  "es": "Tu alineador actual se reemplaza por el que elijas. El historial de uso se conserva.",
  "fr": "Votre gouttière actuelle est remplacée par celle que vous choisissez. L'historique de port est conservé."
 },
 "Your daily goal": {
  "ar": "هدفك اليومي",
  "es": "Tu objetivo diario",
  "fr": "Votre objectif quotidien"
 },
 "Your days will show up here.": {
  "ar": "ستظهر أيامك هنا.",
  "es": "Tus días aparecerán aquí.",
  "fr": "Vos jours apparaîtront ici."
 },
 "Your first name": {
  "ar": "اسمك الأول",
  "es": "Tu nombre",
  "fr": "Votre prénom"
 },
 "Your timer lives in the Dynamic Island and on your Lock Screen, so you can put them back in without opening the app.": {
  "ar": "يعيش مؤقتك في الجزيرة الديناميكية وعلى شاشة القفل، لتعيد المقوّمات دون فتح التطبيق.",
  "es": "Tu temporizador vive en la Dynamic Island y en la pantalla de bloqueo, así puedes ponerlos sin abrir la app.",
  "fr": "Votre minuteur vit dans la Dynamic Island et sur l'écran verrouillé : remettez vos aligneurs sans ouvrir l'app."
 },
 "Your treatment": {
  "ar": "علاجك",
  "es": "Tu tratamiento",
  "fr": "Votre traitement"
 },
 "avg wear %@": {
  "ar": "متوسط الارتداء %@",
  "es": "uso medio %@",
  "fr": "port moy. %@"
 },
 "break#few": {
  "ar": "%d استراحات"
 },
 "break#many": {
  "ar": "%d استراحة"
 },
 "break#one": {
  "ar": "استراحة واحدة",
  "en": "%d break",
  "es": "%d pausa",
  "fr": "%d pause"
 },
 "break#other": {
  "ar": "%d استراحة",
  "en": "%d breaks",
  "es": "%d pausas",
  "fr": "%d pauses"
 },
 "break#two": {
  "ar": "استراحتان"
 },
 "current": {
  "ar": "الحالي",
  "es": "actual",
  "fr": "en cours"
 },
 "day#few": {
  "ar": "%d أيام"
 },
 "day#many": {
  "ar": "%d يومًا"
 },
 "day#one": {
  "ar": "يوم واحد",
  "en": "%d day",
  "es": "%d día",
  "fr": "%d jour"
 },
 "day#other": {
  "ar": "%d يوم",
  "en": "%d days",
  "es": "%d días",
  "fr": "%d jours"
 },
 "day#two": {
  "ar": "يومان"
 },
 "friend": {
  "ar": "صديقي",
  "es": "amigo",
  "fr": "ami"
 },
 "in %@": {
  "ar": "بعد %@",
  "es": "en %@",
  "fr": "dans %@"
 },
 "in progress": {
  "ar": "جارٍ",
  "es": "en curso",
  "fr": "en cours"
 },
 "left": {
  "ar": "متبقي",
  "es": "quedan",
  "fr": "restant"
 },
 "met": {
  "ar": "تحقق",
  "es": "cumplido",
  "fr": "atteint"
 },
 "minute#few": {
  "ar": "%d دقائق"
 },
 "minute#many": {
  "ar": "%d دقيقة"
 },
 "minute#one": {
  "ar": "دقيقة واحدة",
  "en": "%d minute",
  "es": "%d minuto",
  "fr": "%d minute"
 },
 "minute#other": {
  "ar": "%d دقيقة",
  "en": "%d minutes",
  "es": "%d minutos",
  "fr": "%d minutes"
 },
 "minute#two": {
  "ar": "دقيقتان"
 },
 "missed": {
  "ar": "فائت",
  "es": "fallido",
  "fr": "manqué"
 },
 "now": {
  "ar": "الآن",
  "es": "ahora",
  "fr": "maintenant"
 },
 "on plan": {
  "ar": "حسب الخطة",
  "es": "según el plan",
  "fr": "dans le plan"
 },
 "out": {
  "ar": "خارج",
  "es": "fuera",
  "fr": "retiré"
 },
 "switch day": {
  "ar": "يوم التغيير",
  "es": "día de cambio",
  "fr": "jour de changement"
 },
 "today": {
  "ar": "اليوم",
  "es": "hoy",
  "fr": "aujourd'hui"
 },
 "tomorrow": {
  "ar": "غدًا",
  "es": "mañana",
  "fr": "demain"
 },
 "tray started": {
  "ar": "بدء طقم",
  "es": "alineador iniciado",
  "fr": "gouttière démarrée"
 },
 "tray#few": {
  "ar": "%d أطقم"
 },
 "tray#many": {
  "ar": "%d طقمًا"
 },
 "tray#one": {
  "ar": "طقم واحد",
  "en": "%d tray",
  "es": "%d alineador",
  "fr": "%d gouttière"
 },
 "tray#other": {
  "ar": "%d طقم",
  "en": "%d trays",
  "es": "%d alineadores",
  "fr": "%d gouttières"
 },
 "tray#two": {
  "ar": "طقمان"
 },
 "unit.h": {
  "ar": "س",
  "en": "h",
  "es": "h",
  "fr": "h"
 },
 "unit.m": {
  "ar": "د",
  "en": "m",
  "es": "min",
  "fr": "min"
 }
}
"""#
}
