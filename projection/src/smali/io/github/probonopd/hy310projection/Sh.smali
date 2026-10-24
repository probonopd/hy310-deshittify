.class public final Lio/github/probonopd/hy310projection/Sh;
.super Ljava/lang/Object;
.implements Ljava/lang/Runnable;

# One background task: optionally run an act command, then a read command, then hand the
# resulting value to the UI thread. idx < 0 is the root check.

.field static env:Ljava/lang/String;

.field private act:Lio/github/probonopd/hy310projection/ProjectionActivity;
.field private idx:I
.field private read:Ljava/lang/String;
.field private action:Ljava/lang/String;
.field private arg:Ljava/lang/String;
.field private out:Ljava/lang/String;
.field private ui:Z

.method static start(Lio/github/probonopd/hy310projection/ProjectionActivity;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V
    .locals 2
    new-instance v0, Lio/github/probonopd/hy310projection/Sh;
    invoke-direct {v0}, Ljava/lang/Object;-><init>()V
    iput-object p0, v0, Lio/github/probonopd/hy310projection/Sh;->act:Lio/github/probonopd/hy310projection/ProjectionActivity;
    iput p1, v0, Lio/github/probonopd/hy310projection/Sh;->idx:I
    iput-object p2, v0, Lio/github/probonopd/hy310projection/Sh;->read:Ljava/lang/String;
    iput-object p3, v0, Lio/github/probonopd/hy310projection/Sh;->action:Ljava/lang/String;
    iput-object p4, v0, Lio/github/probonopd/hy310projection/Sh;->arg:Ljava/lang/String;
    new-instance v1, Ljava/lang/Thread;
    invoke-direct {v1, v0}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;)V
    invoke-virtual {v1}, Ljava/lang/Thread;->start()V
    return-void
.end method

.method public run()V
    .locals 3
    iget-boolean v0, p0, Lio/github/probonopd/hy310projection/Sh;->ui:Z
    if-eqz v0, :work
    iget-object v0, p0, Lio/github/probonopd/hy310projection/Sh;->act:Lio/github/probonopd/hy310projection/ProjectionActivity;
    iget v1, p0, Lio/github/probonopd/hy310projection/Sh;->idx:I
    iget-object v2, p0, Lio/github/probonopd/hy310projection/Sh;->out:Ljava/lang/String;
    invoke-virtual {v0, v1, v2}, Lio/github/probonopd/hy310projection/ProjectionActivity;->show(ILjava/lang/String;)V
    return-void

    :work
    iget-object v0, p0, Lio/github/probonopd/hy310projection/Sh;->action:Ljava/lang/String;
    if-eqz v0, :doread
    iget-object v1, p0, Lio/github/probonopd/hy310projection/Sh;->arg:Ljava/lang/String;
    invoke-static {v0, v1}, Lio/github/probonopd/hy310projection/Sh;->run(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    const-string v1, "error"
    invoke-virtual {v0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v1
    if-eqz v1, :doread
    iput-object v0, p0, Lio/github/probonopd/hy310projection/Sh;->out:Ljava/lang/String;
    goto :post

    :doread
    iget-object v0, p0, Lio/github/probonopd/hy310projection/Sh;->read:Ljava/lang/String;
    const-string v1, ""
    invoke-static {v0, v1}, Lio/github/probonopd/hy310projection/Sh;->run(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    iput-object v0, p0, Lio/github/probonopd/hy310projection/Sh;->out:Ljava/lang/String;

    :post
    const/4 v0, 0x1
    iput-boolean v0, p0, Lio/github/probonopd/hy310projection/Sh;->ui:Z
    iget-object v0, p0, Lio/github/probonopd/hy310projection/Sh;->act:Lio/github/probonopd/hy310projection/ProjectionActivity;
    invoke-virtual {v0, p0}, Landroid/app/Activity;->runOnUiThread(Ljava/lang/Runnable;)V
    return-void
.end method

# Runs the snippet as root with P and APK set and $1 = arg; stderr is merged so failures stay visible.
.method static run(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 8
    :try_start
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    sget-object v1, Lio/github/probonopd/hy310projection/Sh;->env:Ljava/lang/String;
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, " sh -c \'"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, "\'"
    const-string v2, "\'\\\'\'"
    invoke-virtual {p0, v1, v2}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;
    move-result-object v1
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, "\' sh \'"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, "\'"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0

    const/4 v1, 0x3
    new-array v1, v1, [Ljava/lang/String;
    const/4 v2, 0x0
    const-string v3, "su"
    aput-object v3, v1, v2
    const/4 v2, 0x1
    const-string v3, "-c"
    aput-object v3, v1, v2
    const/4 v2, 0x2
    aput-object v0, v1, v2
    new-instance v0, Ljava/lang/ProcessBuilder;
    invoke-direct {v0, v1}, Ljava/lang/ProcessBuilder;-><init>([Ljava/lang/String;)V
    const/4 v1, 0x1
    invoke-virtual {v0, v1}, Ljava/lang/ProcessBuilder;->redirectErrorStream(Z)Ljava/lang/ProcessBuilder;
    invoke-virtual {v0}, Ljava/lang/ProcessBuilder;->start()Ljava/lang/Process;
    move-result-object v0
    invoke-virtual {v0}, Ljava/lang/Process;->getOutputStream()Ljava/io/OutputStream;
    move-result-object v1
    invoke-virtual {v1}, Ljava/io/OutputStream;->close()V

    invoke-virtual {v0}, Ljava/lang/Process;->getInputStream()Ljava/io/InputStream;
    move-result-object v1
    new-instance v2, Ljava/io/ByteArrayOutputStream;
    invoke-direct {v2}, Ljava/io/ByteArrayOutputStream;-><init>()V
    const/16 v3, 0x1000
    new-array v3, v3, [B
    :loop
    invoke-virtual {v1, v3}, Ljava/io/InputStream;->read([B)I
    move-result v4
    if-ltz v4, :done
    const/4 v5, 0x0
    invoke-virtual {v2, v3, v5, v4}, Ljava/io/ByteArrayOutputStream;->write([BII)V
    goto :loop
    :done
    invoke-virtual {v0}, Ljava/lang/Process;->waitFor()I
    move-result v4
    invoke-virtual {v2}, Ljava/io/ByteArrayOutputStream;->toString()Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v2}, Ljava/lang/String;->trim()Ljava/lang/String;
    move-result-object v2
    if-eqz v4, :ok

    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    const-string v1, "error: exit "
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, v4}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v1, ": "
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v2

    :ok
    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :fail
    return-object v2

    :fail
    move-exception v0
    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V
    const-string v2, "error: "
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method
