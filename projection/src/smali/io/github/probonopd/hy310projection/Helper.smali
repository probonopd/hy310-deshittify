.class public Lio/github/probonopd/hy310projection/Helper;
.super Ljava/lang/Object;

# Root-side command line tool, run via app_process. Talks to the vendor tvserver
# HIDL service directly so the vendor launcher is not needed.
# Transaction codes (from the vendor ITvServer proxy): 0x8c set panel value, 0x8d get panel value.

.method public static main([Ljava/lang/String;)V
    .locals 4

    array-length v0, p0
    if-nez v0, :have_cmd
    const-string v0, "usage: get-mirror | set-mirror N"
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
