.class public Lio/github/probonopd/hy310projection/KeystoneActivity;
.super Landroid/app/Activity;

# Shows what the root script keystone.sh prints and forwards the remote's keys to it. The script owns
# the corner state and the compositor calls, so this class only moves text and key events.

.field tv:Landroid/widget/TextView;
.field kv:Lio/github/probonopd/hy310projection/KeystoneView;
.field private out:Ljava/io/OutputStream;
.field private proc:Ljava/lang/Process;

.method public constructor <init>()V
    .locals 0
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V
    return-void
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .locals 7
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    invoke-virtual {p0}, Landroid/app/Activity;->getWindow()Landroid/view/Window;
    move-result-object v0
    const/16 v1, 0x80
    invoke-virtual {v0, v1}, Landroid/view/Window;->addFlags(I)V

    new-instance v0, Landroid/widget/TextView;
    invoke-direct {v0, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    iput-object v0, p0, Lio/github/probonopd/hy310projection/KeystoneActivity;->tv:Landroid/widget/TextView;
    const/high16 v1, 0x41f00000
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setTextSize(F)V
    const/4 v1, -0x1
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setTextColor(I)V
    sget-object v1, Landroid/graphics/Typeface;->MONOSPACE:Landroid/graphics/Typeface;
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setTypeface(Landroid/graphics/Typeface;)V
    const/16 v1, 0x30
    invoke-virtual {v0, v1, v1, v1, v1}, Landroid/view/View;->setPadding(IIII)V
    const/16 v1, 0x13
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setGravity(I)V
    const-string v1, "Starting..."
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    new-instance v1, Lio/github/probonopd/hy310projection/KeystoneView;
    invoke-direct {v1, p0}, Lio/github/probonopd/hy310projection/KeystoneView;-><init>(Landroid/content/Context;)V
    iput-object v1, p0, Lio/github/probonopd/hy310projection/KeystoneActivity;->kv:Lio/github/probonopd/hy310projection/KeystoneView;
    const/high16 v2, -0x1000000
    invoke-virtual {v1, v2}, Landroid/view/View;->setBackgroundColor(I)V
    new-instance v2, Landroid/widget/FrameLayout;
    invoke-direct {v2, p0}, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V
    invoke-virtual {v2, v1}, Landroid/view/ViewGroup;->addView(Landroid/view/View;)V
    new-instance v3, Landroid/widget/FrameLayout$LayoutParams;
    const/4 v4, -0x2
    const/16 v5, 0x11
    invoke-direct {v3, v4, v4, v5}, Landroid/widget/FrameLayout$LayoutParams;-><init>(III)V
    invoke-virtual {v2, v0, v3}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
    invoke-virtual {p0, v2}, Landroid/app/Activity;->setContentView(Landroid/view/View;)V

    invoke-virtual {p0}, Landroid/app/Activity;->getFilesDir()Ljava/io/File;
    move-result-object v1
    invoke-virtual {v1}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;
    move-result-object v1
    new-instance v2, Ljava/lang/StringBuilder;
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V
    const-string v3, "P="
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v3, " sh "
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v3, "/keystone.sh server 2>&1"
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v2

    const/4 v3, 0x3
    new-array v3, v3, [Ljava/lang/String;
    const-string v4, "su"
    const/4 v5, 0x0
    aput-object v4, v3, v5
    const-string v4, "-c"
    const/4 v5, 0x1
    aput-object v4, v3, v5
    const/4 v5, 0x2
    aput-object v2, v3, v5
    invoke-static {}, Ljava/lang/Runtime;->getRuntime()Ljava/lang/Runtime;
    move-result-object v4
    invoke-virtual {v4, v3}, Ljava/lang/Runtime;->exec([Ljava/lang/String;)Ljava/lang/Process;
    move-result-object v4
    iput-object v4, p0, Lio/github/probonopd/hy310projection/KeystoneActivity;->proc:Ljava/lang/Process;
    invoke-virtual {v4}, Ljava/lang/Process;->getOutputStream()Ljava/io/OutputStream;
    move-result-object v5
    iput-object v5, p0, Lio/github/probonopd/hy310projection/KeystoneActivity;->out:Ljava/io/OutputStream;
    invoke-virtual {v4}, Ljava/lang/Process;->getInputStream()Ljava/io/InputStream;
    move-result-object v5
    new-instance v6, Lio/github/probonopd/hy310projection/KeystoneActivity$Reader;
    invoke-direct {v6, p0, v5}, Lio/github/probonopd/hy310projection/KeystoneActivity$Reader;-><init>(Lio/github/probonopd/hy310projection/KeystoneActivity;Ljava/io/InputStream;)V
    new-instance v5, Ljava/lang/Thread;
    invoke-direct {v5, v6}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;)V
    invoke-virtual {v5}, Ljava/lang/Thread;->start()V
    return-void
.end method

.method public show(Ljava/lang/String;)V
    .locals 3
    const/16 v0, 0x7c
    const/16 v1, 0xa
    invoke-virtual {p1, v0, v1}, Ljava/lang/String;->replace(CC)Ljava/lang/String;
    move-result-object v0
    iget-object v1, p0, Lio/github/probonopd/hy310projection/KeystoneActivity;->tv:Landroid/widget/TextView;
    invoke-virtual {v1, v0}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    iget-object v1, p0, Lio/github/probonopd/hy310projection/KeystoneActivity;->kv:Lio/github/probonopd/hy310projection/KeystoneView;
    const-string v2, "> top right"
    invoke-virtual {p1, v2}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v2
    if-nez v2, :tr
    const-string v2, "> bottom right"
    invoke-virtual {p1, v2}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v2
    if-nez v2, :br
    const-string v2, "> bottom left"
    invoke-virtual {p1, v2}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v2
    if-nez v2, :bl
    const/4 v2, 0x0
    goto :set
    :tr
    const/4 v2, 0x1
    goto :set
    :br
    const/4 v2, 0x2
    goto :set
    :bl
    const/4 v2, 0x3
    :set
    invoke-virtual {v1, v2}, Lio/github/probonopd/hy310projection/KeystoneView;->setSel(I)V
    return-void
.end method

.method public onKeyDown(ILandroid/view/KeyEvent;)Z
    .locals 4
    # DPAD up, down, left, right, center and ENTER go to the script
    const/16 v0, 0x13
    if-lt p1, v0, :other
    const/16 v0, 0x17
    if-le p1, v0, :forward
    const/16 v0, 0x42
    if-ne p1, v0, :other

    :forward
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    const-string v1, "key "
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v1, " "
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {p2}, Landroid/view/KeyEvent;->getRepeatCount()I
    move-result v1
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v1, "\n"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    invoke-virtual {v0}, Ljava/lang/String;->getBytes()[B
    move-result-object v0
    iget-object v1, p0, Lio/github/probonopd/hy310projection/KeystoneActivity;->out:Ljava/io/OutputStream;
    invoke-virtual {v1, v0}, Ljava/io/OutputStream;->write([B)V
    invoke-virtual {v1}, Ljava/io/OutputStream;->flush()V
    const/4 v0, 0x1
    return v0

    :other
    invoke-super {p0, p1, p2}, Landroid/app/Activity;->onKeyDown(ILandroid/view/KeyEvent;)Z
    move-result v0
    return v0
.end method

.method protected onDestroy()V
    .locals 1
    invoke-super {p0}, Landroid/app/Activity;->onDestroy()V
    iget-object v0, p0, Lio/github/probonopd/hy310projection/KeystoneActivity;->out:Ljava/io/OutputStream;
    invoke-virtual {v0}, Ljava/io/OutputStream;->close()V
    iget-object v0, p0, Lio/github/probonopd/hy310projection/KeystoneActivity;->proc:Ljava/lang/Process;
    invoke-virtual {v0}, Ljava/lang/Process;->destroy()V
    return-void
.end method
