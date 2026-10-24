.class public Lio/github/probonopd/hy310projection/Helper;
.super Ljava/lang/Object;

# Root-side command line tool, run via app_process. Talks to the vendor tvserver
# HIDL service directly so the vendor launcher is not needed.
# Transaction codes (from the vendor ITvServer proxy): 0x8c set panel value, 0x8d get panel value,
# 0x66/0x67 set/get PQ value, 0x68/0x69 set/get picture mode name, 0x98/0x99 set/get power mode.

.method private static mirror([Ljava/lang/String;)V
    .locals 4

    array-length v0, p0
    if-nez v0, :have_cmd
    const-string v0, "usage: get-mirror | set-mirror N | get-pq T | set-pq T V | get-picmode | set-picmode NAME | get-power | set-power N | set-audio-mode N"
    goto :usage

    :have_cmd
    const/4 v0, 0x0
    aget-object v0, p0, v0
    const-string v1, "get-mirror"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :not_get

    # 3 is the MIRROR panel config type
    const/4 v0, 0x3
    const/16 v1, 0x8d
    const/4 v2, 0x0
    invoke-static {v1, v0, v2, v2}, Lio/github/probonopd/hy310projection/Helper;->call(IIII)I
    move-result v0
    sget-object v1, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(I)V
    return-void

    :not_get
    const/4 v0, 0x0
    aget-object v0, p0, v0
    const-string v1, "set-mirror"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :bad
    array-length v1, p0
    const/4 v2, 0x2
    if-ne v1, v2, :bad

    const/4 v1, 0x1
    aget-object v1, p0, v1
    invoke-static {v1}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I
    move-result v1
    if-ltz v1, :bad
    const/4 v2, 0x3
    if-gt v1, v2, :bad

    const/16 v0, 0x8c
    const/4 v3, 0x1
    invoke-static {v0, v2, v1, v3}, Lio/github/probonopd/hy310projection/Helper;->call(IIII)I
    move-result v0
    sget-object v1, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(I)V
    return-void

    :bad
    const-string v0, "usage: get-mirror | set-mirror N (N=0..3)"
    :usage
    sget-object v1, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v1, v0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/4 v0, 0x2
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

# code: transaction; type: panel config type; value: written only if hasValue != 0.
# Returns the int32 result. Throws (fails hard) on a missing service or transaction error.
.method private static call(IIII)I
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    const-string v0, "vendor.aw.homlet.tvsystem.tvserver@1.0::ITvServer"
    const-string v1, "default"
    invoke-static {v0, v1}, Landroid/os/HwBinder;->getService(Ljava/lang/String;Ljava/lang/String;)Landroid/os/IHwBinder;
    move-result-object v1
    if-nez v1, :got
    new-instance v0, Ljava/lang/IllegalStateException;
    const-string v1, "tvserver HIDL service not found"
    invoke-direct {v0, v1}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;)V
    throw v0

    :got
    new-instance v2, Landroid/os/HwParcel;
    invoke-direct {v2}, Landroid/os/HwParcel;-><init>()V
    invoke-virtual {v2, v0}, Landroid/os/HwParcel;->writeInterfaceToken(Ljava/lang/String;)V
    invoke-virtual {v2, p1}, Landroid/os/HwParcel;->writeInt32(I)V
    if-eqz p3, :no_value
    invoke-virtual {v2, p2}, Landroid/os/HwParcel;->writeInt32(I)V

    :no_value
    new-instance v3, Landroid/os/HwParcel;
    invoke-direct {v3}, Landroid/os/HwParcel;-><init>()V
    const/4 v4, 0x0
    invoke-interface {v1, p0, v2, v3, v4}, Landroid/os/IHwBinder;->transact(ILandroid/os/HwParcel;Landroid/os/HwParcel;I)V
    invoke-virtual {v3}, Landroid/os/HwParcel;->verifySuccess()V
    invoke-virtual {v2}, Landroid/os/HwParcel;->releaseTemporaryStorage()V
    invoke-virtual {v3}, Landroid/os/HwParcel;->readInt32()I
    move-result v5
    invoke-virtual {v3}, Landroid/os/HwParcel;->release()V
    return v5
.end method

# Dispatches the picture and power commands; anything else goes to the mirror commands.
.method public static main([Ljava/lang/String;)V
    .locals 5

    array-length v0, p0
    if-eqz v0, :mirror
    const/4 v0, 0x0
    aget-object v0, p0, v0

    const-string v1, "get-pq"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :n1
    const/4 v1, 0x2
    invoke-static {p0, v1}, Lio/github/probonopd/hy310projection/Helper;->need([Ljava/lang/String;I)V
    # only types 1..5 (brightness..sharpness); backlight types must stay unreachable
    const/4 v1, 0x1
    const/4 v2, 0x1
    const/4 v3, 0x5
    invoke-static {p0, v1, v2, v3}, Lio/github/probonopd/hy310projection/Helper;->intArg([Ljava/lang/String;III)I
    move-result v1
    invoke-static {}, Lio/github/probonopd/hy310projection/Helper;->newReq()Landroid/os/HwParcel;
    move-result-object v2
    invoke-virtual {v2, v1}, Landroid/os/HwParcel;->writeInt32(I)V
    const/16 v3, 0x67
    invoke-static {v3, v2}, Lio/github/probonopd/hy310projection/Helper;->transact(ILandroid/os/HwParcel;)Landroid/os/HwParcel;
    move-result-object v3
    invoke-virtual {v3}, Landroid/os/HwParcel;->readInt32()I
    move-result v3
    sget-object v4, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v4, v3}, Ljava/io/PrintStream;->println(I)V
    return-void

    :n1
    const-string v1, "set-pq"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :n2
    const/4 v1, 0x3
    invoke-static {p0, v1}, Lio/github/probonopd/hy310projection/Helper;->need([Ljava/lang/String;I)V
    const/4 v1, 0x1
    const/4 v2, 0x1
    const/4 v3, 0x5
    invoke-static {p0, v1, v2, v3}, Lio/github/probonopd/hy310projection/Helper;->intArg([Ljava/lang/String;III)I
    move-result v1
    const/4 v2, 0x2
    const/4 v3, 0x1
    const/16 v4, 0x64
    invoke-static {p0, v2, v3, v4}, Lio/github/probonopd/hy310projection/Helper;->intArg([Ljava/lang/String;III)I
    move-result v2
    invoke-static {}, Lio/github/probonopd/hy310projection/Helper;->newReq()Landroid/os/HwParcel;
    move-result-object v3
    invoke-virtual {v3, v1}, Landroid/os/HwParcel;->writeInt32(I)V
    invoke-virtual {v3, v2}, Landroid/os/HwParcel;->writeInt32(I)V
    const/16 v4, 0x66
    invoke-static {v4, v3}, Lio/github/probonopd/hy310projection/Helper;->transact(ILandroid/os/HwParcel;)Landroid/os/HwParcel;
    move-result-object v3
    invoke-virtual {v3}, Landroid/os/HwParcel;->readInt32()I
    move-result v3
    sget-object v4, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v4, v3}, Ljava/io/PrintStream;->println(I)V
    return-void

    :n2
    const-string v1, "get-picmode"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :n3
    const/4 v1, 0x1
    invoke-static {p0, v1}, Lio/github/probonopd/hy310projection/Helper;->need([Ljava/lang/String;I)V
    invoke-static {}, Lio/github/probonopd/hy310projection/Helper;->newReq()Landroid/os/HwParcel;
    move-result-object v2
    const/16 v3, 0x69
    invoke-static {v3, v2}, Lio/github/probonopd/hy310projection/Helper;->transact(ILandroid/os/HwParcel;)Landroid/os/HwParcel;
    move-result-object v3
    invoke-virtual {v3}, Landroid/os/HwParcel;->readString()Ljava/lang/String;
    move-result-object v3
    sget-object v4, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v4, v3}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    return-void

    :n3
    const-string v1, "set-picmode"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :n4
    const/4 v1, 0x2
    invoke-static {p0, v1}, Lio/github/probonopd/hy310projection/Helper;->need([Ljava/lang/String;I)V
    const/4 v1, 0x1
    aget-object v1, p0, v1
    invoke-static {v1}, Lio/github/probonopd/hy310projection/Helper;->checkName(Ljava/lang/String;)V
    invoke-static {}, Lio/github/probonopd/hy310projection/Helper;->newReq()Landroid/os/HwParcel;
    move-result-object v2
    invoke-virtual {v2, v1}, Landroid/os/HwParcel;->writeString(Ljava/lang/String;)V
    const/16 v3, 0x68
    invoke-static {v3, v2}, Lio/github/probonopd/hy310projection/Helper;->transact(ILandroid/os/HwParcel;)Landroid/os/HwParcel;
    move-result-object v3
    invoke-virtual {v3}, Landroid/os/HwParcel;->readInt32()I
    move-result v3
    sget-object v4, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v4, v3}, Ljava/io/PrintStream;->println(I)V
    return-void

    :n4
    const-string v1, "get-power"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :n5
    const/4 v1, 0x1
    invoke-static {p0, v1}, Lio/github/probonopd/hy310projection/Helper;->need([Ljava/lang/String;I)V
    invoke-static {}, Lio/github/probonopd/hy310projection/Helper;->newReq()Landroid/os/HwParcel;
    move-result-object v2
    const/16 v3, 0x99
    invoke-static {v3, v2}, Lio/github/probonopd/hy310projection/Helper;->transact(ILandroid/os/HwParcel;)Landroid/os/HwParcel;
    move-result-object v3
    invoke-virtual {v3}, Landroid/os/HwParcel;->readInt32()I
    move-result v3
    sget-object v4, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v4, v3}, Ljava/io/PrintStream;->println(I)V
    return-void

    :n5
    const-string v1, "set-power"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :audio
    const/4 v1, 0x2
    invoke-static {p0, v1}, Lio/github/probonopd/hy310projection/Helper;->need([Ljava/lang/String;I)V
    const/4 v1, 0x1
    const/4 v2, 0x0
    invoke-static {p0, v1, v2, v1}, Lio/github/probonopd/hy310projection/Helper;->intArg([Ljava/lang/String;III)I
    move-result v1
    invoke-static {}, Lio/github/probonopd/hy310projection/Helper;->newReq()Landroid/os/HwParcel;
    move-result-object v2
    invoke-virtual {v2, v1}, Landroid/os/HwParcel;->writeInt32(I)V
    const/16 v3, 0x98
    invoke-static {v3, v2}, Lio/github/probonopd/hy310projection/Helper;->transact(ILandroid/os/HwParcel;)Landroid/os/HwParcel;
    move-result-object v3
    invoke-virtual {v3}, Landroid/os/HwParcel;->readInt32()I
    move-result v3
    sget-object v4, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v4, v3}, Ljava/io/PrintStream;->println(I)V
    return-void

    :audio
    const-string v1, "set-audio-mode"
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :mirror
    const/4 v1, 0x2
    invoke-static {p0, v1}, Lio/github/probonopd/hy310projection/Helper;->need([Ljava/lang/String;I)V
    # 0 standard, 1 music, 2 movie, 3 news: the audio HAL key the vendor launcher sets
    const/4 v1, 0x1
    const/4 v2, 0x0
    const/4 v3, 0x3
    invoke-static {p0, v1, v2, v3}, Lio/github/probonopd/hy310projection/Helper;->intArg([Ljava/lang/String;III)I
    move-result v1
    new-instance v2, Ljava/lang/StringBuilder;
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V
    const-string v3, "audio_mode="
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v2
    invoke-static {v2}, Landroid/media/AudioSystem;->setParameters(Ljava/lang/String;)I
    move-result v3
    sget-object v4, Ljava/lang/System;->out:Ljava/io/PrintStream;
    invoke-virtual {v4, v3}, Ljava/io/PrintStream;->println(I)V
    return-void

    :mirror
    invoke-static {p0}, Lio/github/probonopd/hy310projection/Helper;->mirror([Ljava/lang/String;)V
    return-void
.end method

.method private static fail(Ljava/lang/String;)V
    .locals 2
    sget-object v0, Ljava/lang/System;->err:Ljava/io/PrintStream;
    invoke-virtual {v0, p0}, Ljava/io/PrintStream;->println(Ljava/lang/String;)V
    const/4 v0, 0x2
    invoke-static {v0}, Ljava/lang/System;->exit(I)V
    return-void
.end method

# Exactly n arguments including the command name.
.method private static need([Ljava/lang/String;I)V
    .locals 2
    array-length v0, p0
    if-eq v0, p1, :ok
    const-string v0, "error: wrong number of arguments"
    invoke-static {v0}, Lio/github/probonopd/hy310projection/Helper;->fail(Ljava/lang/String;)V
    :ok
    return-void
.end method

# Integer argument at idx that must lie in lo..hi; fails loudly otherwise.
.method private static intArg([Ljava/lang/String;III)I
    .locals 4
    :try_start
    aget-object v0, p0, p1
    invoke-static {v0}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I
    move-result v0
    :try_end
    .catch Ljava/lang/NumberFormatException; {:try_start .. :try_end} :bad
    if-lt v0, p2, :bad
    if-gt v0, p3, :bad
    return v0
    :bad
    const-string v0, "error: argument out of range or not a number"
    invoke-static {v0}, Lio/github/probonopd/hy310projection/Helper;->fail(Ljava/lang/String;)V
    const/4 v0, 0x0
    return v0
.end method

.method private static checkName(Ljava/lang/String;)V
    .locals 2
    const-string v0, "standard"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :ok
    const-string v0, "cinema"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :ok
    const-string v0, "vivid"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :ok
    const-string v0, "custom"
    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :ok
    const-string v0, "error: picture mode must be standard, cinema, vivid or custom"
    invoke-static {v0}, Lio/github/probonopd/hy310projection/Helper;->fail(Ljava/lang/String;)V
    :ok
    return-void
.end method

.method private static newReq()Landroid/os/HwParcel;
    .locals 2
    new-instance v0, Landroid/os/HwParcel;
    invoke-direct {v0}, Landroid/os/HwParcel;-><init>()V
    const-string v1, "vendor.aw.homlet.tvsystem.tvserver@1.0::ITvServer"
    invoke-virtual {v0, v1}, Landroid/os/HwParcel;->writeInterfaceToken(Ljava/lang/String;)V
    return-object v0
.end method

# Returns the reply parcel; throws (fails hard) on a missing service or transaction error.
.method private static transact(ILandroid/os/HwParcel;)Landroid/os/HwParcel;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    const-string v0, "vendor.aw.homlet.tvsystem.tvserver@1.0::ITvServer"
    const-string v1, "default"
    invoke-static {v0, v1}, Landroid/os/HwBinder;->getService(Ljava/lang/String;Ljava/lang/String;)Landroid/os/IHwBinder;
    move-result-object v1
    if-nez v1, :got
    new-instance v0, Ljava/lang/IllegalStateException;
    const-string v1, "tvserver HIDL service not found"
    invoke-direct {v0, v1}, Ljava/lang/IllegalStateException;-><init>(Ljava/lang/String;)V
    throw v0

    :got
    new-instance v2, Landroid/os/HwParcel;
    invoke-direct {v2}, Landroid/os/HwParcel;-><init>()V
    const/4 v3, 0x0
    invoke-interface {v1, p0, p1, v2, v3}, Landroid/os/IHwBinder;->transact(ILandroid/os/HwParcel;Landroid/os/HwParcel;I)V
    invoke-virtual {v2}, Landroid/os/HwParcel;->verifySuccess()V
    invoke-virtual {p1}, Landroid/os/HwParcel;->releaseTemporaryStorage()V
    return-object v2
.end method
