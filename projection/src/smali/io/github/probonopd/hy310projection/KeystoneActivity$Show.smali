.class Lio/github/probonopd/hy310projection/KeystoneActivity$Show;
.super Ljava/lang/Object;
.implements Ljava/lang/Runnable;

.field private act:Lio/github/probonopd/hy310projection/KeystoneActivity;
.field private text:Ljava/lang/String;

.method constructor <init>(Lio/github/probonopd/hy310projection/KeystoneActivity;Ljava/lang/String;)V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    iput-object p1, p0, Lio/github/probonopd/hy310projection/KeystoneActivity$Show;->act:Lio/github/probonopd/hy310projection/KeystoneActivity;
    iput-object p2, p0, Lio/github/probonopd/hy310projection/KeystoneActivity$Show;->text:Ljava/lang/String;
    return-void
.end method

.method public run()V
    .locals 2
    iget-object v0, p0, Lio/github/probonopd/hy310projection/KeystoneActivity$Show;->act:Lio/github/probonopd/hy310projection/KeystoneActivity;
    iget-object v1, p0, Lio/github/probonopd/hy310projection/KeystoneActivity$Show;->text:Ljava/lang/String;
    invoke-virtual {v0, v1}, Lio/github/probonopd/hy310projection/KeystoneActivity;->show(Ljava/lang/String;)V
    return-void
.end method
