from traitlets import Unicode

from jupyterhub.auth import Authenticator

class NologinAuthenticator(Authenticator):
    """Nologin Authenticator for testing
    """

    username = Unicode(
        config=True,
        default_value='jovyan',
        help="""
        Set a global user name for everyone.
        """,
    )

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.admin_users.add(self.username)
        self.auto_login = True

    async def authenticate(self, handler, data):
        """Checks against a global password if it's been set. If not, allow any user/pass combo"""
        return self.username
