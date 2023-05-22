import kubespawner

class KubeSpawner(kubespawner.KubeSpawner):
    async def load_user_options(self):
        """Override: rewrite profile from customized user_options"""
        options_profile = self.user_options.get('profile', None)
        if not options_profile:
            self.log.warning("User options has none profile")
            return
        options_profile.update({'default': True})
        if 'display_name' not in options_profile:
            options_profile['display_name'] = 'customized'
        self._profile_list = self._init_profile_list([options_profile])
        await self._load_profile(None, {})
