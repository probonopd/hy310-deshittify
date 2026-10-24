.class public Lio/github/probonopd/hy310projection/ProjectionActivity;
.super Landroid/app/Activity;
.implements Landroid/view/View$OnClickListener;

# Remote-friendly list of rows built from the string-array "rows" (Label@@read@@act).
# All behavior lives in the array; shell work runs on background threads in Sh.

.field private items:Ljava/util/ArrayList;
.field private views:Ljava/util/ArrayList;
.field private notice:Landroid/widget/TextView;

.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V
    return-void
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .locals 12
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    const-string v1, "P="
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {p0}, Landroid/content/Context;->getFilesDir()Ljava/io/File;
    move-result-object v1
    invoke-virtual {v1}, Ljava/io/File;->getPath()Ljava/lang/String;
    move-result-object v1
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, " APK="
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {p0}, Landroid/content/Context;->getApplicationInfo()Landroid/content/pm/ApplicationInfo;
    move-result-object v1
    iget-object v1, v1, Landroid/content/pm/ApplicationInfo;->sourceDir:Ljava/lang/String;
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    sput-object v0, Lio/github/probonopd/hy310projection/Sh;->env:Ljava/lang/String;

    invoke-direct {p0}, Lio/github/probonopd/hy310projection/ProjectionActivity;->installScripts()V

    invoke-virtual {p0}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v0
    const-string v1, "rows"
    const-string v2, "array"
    invoke-virtual {p0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;
    move-result-object v3
    invoke-virtual {v0, v1, v2, v3}, Landroid/content/res/Resources;->getIdentifier(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I
    move-result v1
    invoke-virtual {v0, v1}, Landroid/content/res/Resources;->getStringArray(I)[Ljava/lang/String;
    move-result-object v0

    new-instance v1, Ljava/util/ArrayList;
    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V
    iput-object v1, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->items:Ljava/util/ArrayList;
    new-instance v1, Ljava/util/ArrayList;
    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V
    iput-object v1, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->views:Ljava/util/ArrayList;

    new-instance v1, Landroid/widget/ScrollView;
    invoke-direct {v1, p0}, Landroid/widget/ScrollView;-><init>(Landroid/content/Context;)V
    const v2, 0xff101010
    invoke-virtual {v1, v2}, Landroid/view/View;->setBackgroundColor(I)V
    new-instance v2, Landroid/widget/LinearLayout;
    invoke-direct {v2, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    const/4 v3, 0x1
    invoke-virtual {v2, v3}, Landroid/widget/LinearLayout;->setOrientation(I)V
    const/16 v3, 0x30
    invoke-virtual {v2, v3, v3, v3, v3}, Landroid/view/View;->setPadding(IIII)V

    new-instance v3, Landroid/widget/TextView;
    invoke-direct {v3, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    iput-object v3, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->notice:Landroid/widget/TextView;
    const v4, 0xffff8a80
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextColor(I)V
    const/high16 v4, 0x41e00000
    invoke-virtual {v3, v4}, Landroid/widget/TextView;->setTextSize(F)V
    const/4 v4, 0x0
    const/16 v5, 0x18
    invoke-virtual {v3, v4, v4, v4, v5}, Landroid/view/View;->setPadding(IIII)V
    const/16 v4, 0x8
    invoke-virtual {v3, v4}, Landroid/view/View;->setVisibility(I)V
    invoke-virtual {v2, v3}, Landroid/view/ViewGroup;->addView(Landroid/view/View;)V

    array-length v5, v0
    const/4 v6, 0x0
    :loop
    if-ge v6, v5, :end
    aget-object v7, v0, v6
    const-string v8, "@@"
    invoke-virtual {v7, v8}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;
    move-result-object v7
    iget-object v8, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->items:Ljava/util/ArrayList;
    invoke-virtual {v8, v7}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    new-instance v8, Landroid/widget/TextView;
    invoke-direct {v8, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    const/high16 v9, 0x42100000
    invoke-virtual {v8, v9}, Landroid/widget/TextView;->setTextSize(F)V
    const/4 v9, -0x1
    invoke-virtual {v8, v9}, Landroid/widget/TextView;->setTextColor(I)V
    const/16 v9, 0x28
    const/16 v10, 0x1c
    invoke-virtual {v8, v9, v10, v9, v10}, Landroid/view/View;->setPadding(IIII)V
    const/4 v9, 0x1
    invoke-virtual {v8, v9}, Landroid/view/View;->setFocusable(Z)V
    invoke-virtual {v8, v9}, Landroid/view/View;->setClickable(Z)V
    invoke-virtual {v8, p0}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V
    invoke-direct {p0}, Lio/github/probonopd/hy310projection/ProjectionActivity;->bg()Landroid/graphics/drawable/Drawable;
    move-result-object v9
    invoke-virtual {v8, v9}, Landroid/view/View;->setBackground(Landroid/graphics/drawable/Drawable;)V
    new-instance v9, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v10, -0x1
    const/4 v11, -0x2
    invoke-direct {v9, v10, v11}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    const/4 v10, 0x0
    const/16 v11, 0x10
    invoke-virtual {v9, v10, v10, v10, v11}, Landroid/view/ViewGroup$MarginLayoutParams;->setMargins(IIII)V
    invoke-virtual {v2, v8, v9}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
    iget-object v9, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->views:Ljava/util/ArrayList;
    invoke-virtual {v9, v8}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z
    const-string v9, "..."
    invoke-direct {p0, v6, v9}, Lio/github/probonopd/hy310projection/ProjectionActivity;->text(ILjava/lang/String;)V
    add-int/lit8 v6, v6, 0x1
    goto :loop

    :end
    invoke-virtual {v1, v2}, Landroid/view/ViewGroup;->addView(Landroid/view/View;)V
    invoke-virtual {p0, v1}, Landroid/app/Activity;->setContentView(Landroid/view/View;)V
    return-void
.end method

# Scripts ship as string resources named script_<name>; resource ids are scanned because no R class exists.
.method private installScripts()V
    .locals 9
    invoke-virtual {p0}, Landroid/content/Context;->getResources()Landroid/content/res/Resources;
    move-result-object v0
    const/4 v1, 0x1

    :type
    const/16 v2, 0x20
    if-gt v1, v2, :done
    const/4 v3, 0x0

    :entry
    shl-int/lit8 v4, v1, 0x10
    const/high16 v5, 0x7f000000
    or-int/2addr v4, v5
    or-int/2addr v4, v3
    :try_start
    invoke-virtual {v0, v4}, Landroid/content/res/Resources;->getResourceEntryName(I)Ljava/lang/String;
    move-result-object v5
    :try_end
    .catch Landroid/content/res/Resources$NotFoundException; {:try_start .. :try_end} :nexttype

    const-string v6, "script_"
    invoke-virtual {v5, v6}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v6
    if-eqz v6, :nextentry
    invoke-virtual {p0, v4}, Landroid/content/Context;->getString(I)Ljava/lang/String;
    move-result-object v6
    const/4 v7, 0x7
    invoke-virtual {v5, v7}, Ljava/lang/String;->substring(I)Ljava/lang/String;
    move-result-object v5
    new-instance v7, Ljava/lang/StringBuilder;
    invoke-direct {v7}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v7, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v5, ".sh"
    invoke-virtual {v7, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v5
    const/4 v7, 0x0
    invoke-virtual {p0, v5, v7}, Landroid/content/Context;->openFileOutput(Ljava/lang/String;I)Ljava/io/FileOutputStream;
    move-result-object v5
    invoke-virtual {v6}, Ljava/lang/String;->getBytes()[B
    move-result-object v6
    invoke-virtual {v5, v6}, Ljava/io/OutputStream;->write([B)V
    invoke-virtual {v5}, Ljava/io/OutputStream;->close()V

    :nextentry
    add-int/lit8 v3, v3, 0x1
    goto :entry

    :nexttype
    add-int/lit8 v1, v1, 0x1
    goto :type

    :done
    return-void
.end method

.method private bg()Landroid/graphics/drawable/Drawable;
    .locals 5
    new-instance v0, Landroid/graphics/drawable/StateListDrawable;
    invoke-direct {v0}, Landroid/graphics/drawable/StateListDrawable;-><init>()V
    const/4 v1, 0x1
    new-array v2, v1, [I
    const/4 v3, 0x0
    const v4, 0x101009c
    aput v4, v2, v3
    new-instance v4, Landroid/graphics/drawable/ColorDrawable;
    const v1, 0xff1976d2
    invoke-direct {v4, v1}, Landroid/graphics/drawable/ColorDrawable;-><init>(I)V
    invoke-virtual {v0, v2, v4}, Landroid/graphics/drawable/StateListDrawable;->addState([ILandroid/graphics/drawable/Drawable;)V
    const/4 v1, 0x0
    new-array v2, v1, [I
    new-instance v4, Landroid/graphics/drawable/ColorDrawable;
    const v1, 0xff2a2a2a
    invoke-direct {v4, v1}, Landroid/graphics/drawable/ColorDrawable;-><init>(I)V
    invoke-virtual {v0, v2, v4}, Landroid/graphics/drawable/StateListDrawable;->addState([ILandroid/graphics/drawable/Drawable;)V
    return-object v0
.end method

.method private text(ILjava/lang/String;)V
    .locals 4
    iget-object v0, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->views:Ljava/util/ArrayList;
    invoke-virtual {v0, p1}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
    move-result-object v0
    check-cast v0, Landroid/widget/TextView;
    iget-object v1, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->items:Ljava/util/ArrayList;
    invoke-virtual {v1, p1}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
    move-result-object v1
    check-cast v1, [Ljava/lang/String;
    const/4 v2, 0x0
    aget-object v1, v1, v2
    new-instance v2, Ljava/lang/StringBuilder;
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v3, ": "
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v2, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    return-void
.end method

# idx < 0 is the root check result ("0" = uid 0); otherwise the new value of row idx.
.method public show(ILjava/lang/String;)V
    .locals 3
    if-gez p1, :row
    const-string v0, "0"
    invoke-virtual {p2, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    iget-object v1, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->notice:Landroid/widget/TextView;
    if-eqz v0, :bad
    const/16 v0, 0x8
    invoke-virtual {v1, v0}, Landroid/view/View;->setVisibility(I)V
    invoke-direct {p0}, Lio/github/probonopd/hy310projection/ProjectionActivity;->refreshAll()V
    return-void

    :bad
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    const-string v2, "Root (su) not available: allow it in Magisk ("
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v2, ")"
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    invoke-virtual {v1, v0}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/4 v0, 0x0
    invoke-virtual {v1, v0}, Landroid/view/View;->setVisibility(I)V
    return-void

    :row
    invoke-direct {p0, p1, p2}, Lio/github/probonopd/hy310projection/ProjectionActivity;->text(ILjava/lang/String;)V
    return-void
.end method

.method private refreshAll()V
    .locals 5
    const/4 v0, 0x0
    :loop
    iget-object v1, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->views:Ljava/util/ArrayList;
    invoke-virtual {v1}, Ljava/util/ArrayList;->size()I
    move-result v1
    if-ge v0, v1, :out
    iget-object v1, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->items:Ljava/util/ArrayList;
    invoke-virtual {v1, v0}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
    move-result-object v1
    check-cast v1, [Ljava/lang/String;
    const/4 v2, 0x1
    aget-object v1, v1, v2
    const/4 v2, 0x0
    invoke-static {p0, v0, v1, v2, v2}, Lio/github/probonopd/hy310projection/Sh;->start(Lio/github/probonopd/hy310projection/ProjectionActivity;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    add-int/lit8 v0, v0, 0x1
    goto :loop
    :out
    return-void
.end method

.method private startRow(ILjava/lang/String;)V
    .locals 3
    iget-object v0, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->items:Ljava/util/ArrayList;
    invoke-virtual {v0, p1}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;
    move-result-object v0
    check-cast v0, [Ljava/lang/String;
    const/4 v1, 0x1
    aget-object v1, v0, v1
    const/4 v2, 0x2
    aget-object v2, v0, v2
    invoke-static {p0, p1, v1, v2, p2}, Lio/github/probonopd/hy310projection/Sh;->start(Lio/github/probonopd/hy310projection/ProjectionActivity;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    return-void
.end method

.method protected onResume()V
    .locals 5
    invoke-super {p0}, Landroid/app/Activity;->onResume()V
    const-string v0, "id -u"
    const/4 v1, 0x0
    const/4 v2, -0x1
    invoke-static {p0, v2, v0, v1, v1}, Lio/github/probonopd/hy310projection/Sh;->start(Lio/github/probonopd/hy310projection/ProjectionActivity;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    return-void
.end method

.method public onClick(Landroid/view/View;)V
    .locals 3
    iget-object v0, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->views:Ljava/util/ArrayList;
    invoke-virtual {v0, p1}, Ljava/util/ArrayList;->indexOf(Ljava/lang/Object;)I
    move-result v0
    const-string v1, "1"
    invoke-direct {p0, v0, v1}, Lio/github/probonopd/hy310projection/ProjectionActivity;->startRow(ILjava/lang/String;)V
    return-void
.end method

.method public onKeyDown(ILandroid/view/KeyEvent;)Z
    .locals 3
    const/16 v0, 0x16
    if-ne p1, v0, :notright
    const-string v0, "1"
    goto :act

    :notright
    const/16 v0, 0x15
    if-ne p1, v0, :other
    const-string v0, "-1"

    :act
    invoke-virtual {p0}, Landroid/app/Activity;->getCurrentFocus()Landroid/view/View;
    move-result-object v1
    iget-object v2, p0, Lio/github/probonopd/hy310projection/ProjectionActivity;->views:Ljava/util/ArrayList;
    invoke-virtual {v2, v1}, Ljava/util/ArrayList;->indexOf(Ljava/lang/Object;)I
    move-result v1
    if-ltz v1, :other
    invoke-direct {p0, v1, v0}, Lio/github/probonopd/hy310projection/ProjectionActivity;->startRow(ILjava/lang/String;)V
    const/4 v0, 0x1
    return v0

    :other
    invoke-super {p0, p1, p2}, Landroid/app/Activity;->onKeyDown(ILandroid/view/KeyEvent;)Z
    move-result v0
    return v0
.end method
