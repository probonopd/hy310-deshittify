.class Lio/github/probonopd/hy310projection/KeystoneActivity$Reader;
.super Ljava/lang/Object;
.implements Ljava/lang/Runnable;

.field private act:Lio/github/probonopd/hy310projection/KeystoneActivity;
.field private in:Ljava/io/InputStream;

.method constructor <init>(Lio/github/probonopd/hy310projection/KeystoneActivity;Ljava/io/InputStream;)V
    .locals 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    iput-object p1, p0, Lio/github/probonopd/hy310projection/KeystoneActivity$Reader;->act:Lio/github/probonopd/hy310projection/KeystoneActivity;
    iput-object p2, p0, Lio/github/probonopd/hy310projection/KeystoneActivity$Reader;->in:Ljava/io/InputStream;
    return-void
.end method

.method public run()V
    .locals 5
    new-instance v0, Ljava/io/InputStreamReader;
    iget-object v1, p0, Lio/github/probonopd/hy310projection/KeystoneActivity$Reader;->in:Ljava/io/InputStream;
    invoke-direct {v0, v1}, Ljava/io/InputStreamReader;-><init>(Ljava/io/InputStream;)V
    new-instance v1, Ljava/io/BufferedReader;
    invoke-direct {v1, v0}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V

    # reading ends with an IOException when the activity closes the script's pipe, which is the normal exit
    :try_start
    :loop
    invoke-virtual {v1}, Ljava/io/BufferedReader;->readLine()Ljava/lang/String;
    move-result-object v2
    if-eqz v2, :done
    iget-object v3, p0, Lio/github/probonopd/hy310projection/KeystoneActivity$Reader;->act:Lio/github/probonopd/hy310projection/KeystoneActivity;
    new-instance v4, Lio/github/probonopd/hy310projection/KeystoneActivity$Show;
    invoke-direct {v4, v3, v2}, Lio/github/probonopd/hy310projection/KeystoneActivity$Show;-><init>(Lio/github/probonopd/hy310projection/KeystoneActivity;Ljava/lang/String;)V
    iget-object v3, v3, Lio/github/probonopd/hy310projection/KeystoneActivity;->tv:Landroid/widget/TextView;
    invoke-virtual {v3, v4}, Landroid/view/View;->post(Ljava/lang/Runnable;)Z
    goto :loop

    :done
    :try_end
    .catch Ljava/io/IOException; {:try_start .. :try_end} :catch
    return-void

    :catch
    move-exception v2
    return-void
.end method
