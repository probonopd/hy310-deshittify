.class public Lio/github/probonopd/hy310settings/Launch;
.super Landroid/app/Activity;

.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V
    return-void
.end method

# The vendor launcher and the android.settings.* intents point at its own settings app, and
# the stock Settings app's component differs by firmware: the phone-style app
# (com.android.settings/.Settings) on the H713 Android 11 builds, Android TV's own app
# (com.android.tv.settings/.MainSettings) on the H726 Android 14 build. Try both component
# names, in that order, and finally the generic android.settings.SETTINGS intent, so the
# same apk works on whichever one is actually installed instead of hardcoding one.
.method protected onCreate(Landroid/os/Bundle;)V
    .locals 3
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    :try_start_0
    new-instance v0, Landroid/content/Intent;
    invoke-direct {v0}, Landroid/content/Intent;-><init>()V
    const-string v1, "com.android.settings"
    const-string v2, "com.android.settings.Settings"
    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->setClassName(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;
    invoke-virtual {p0, v0}, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
    goto :done
    :try_end_0
    .catch Landroid/content/ActivityNotFoundException; {:try_start_0 .. :try_end_0} :catch_0

    :catch_0
    :try_start_1
    new-instance v0, Landroid/content/Intent;
    invoke-direct {v0}, Landroid/content/Intent;-><init>()V
    const-string v1, "com.android.tv.settings"
    const-string v2, "com.android.tv.settings.MainSettings"
    invoke-virtual {v0, v1, v2}, Landroid/content/Intent;->setClassName(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;
    invoke-virtual {p0, v0}, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
    goto :done
    :try_end_1
    .catch Landroid/content/ActivityNotFoundException; {:try_start_1 .. :try_end_1} :catch_1

    :catch_1
    :try_start_2
    new-instance v0, Landroid/content/Intent;
    const-string v1, "android.settings.SETTINGS"
    invoke-direct {v0, v1}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V
    invoke-virtual {p0, v0}, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
    goto :done
    :try_end_2
    .catch Landroid/content/ActivityNotFoundException; {:try_start_2 .. :try_end_2} :catch_2

    :catch_2
    # Nothing resolved: give up quietly rather than crash.

    :done
    invoke-virtual {p0}, Landroid/app/Activity;->finish()V
    return-void
.end method
