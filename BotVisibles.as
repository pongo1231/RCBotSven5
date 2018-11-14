
const int VIS_FL_NONE = 0;
const int VIS_FL_BODY = 1;
const int VIS_FL_HEAD = 2;

class CBotVisibles
{
	CBotVisibles ( RCBot@ bot )
	{
		@m_pCurrentEntity = null;
		@bits_body = CBits(g_Engine.maxEntities+1);
		@bits_head = CBits(g_Engine.maxEntities+1);
		@m_pBot = bot;
	}

	EHandle m_pNearestAvoid = null;
	float m_fNearestAvoidDist = 0;

	bool CanAvoid ( CBaseEntity@ ent )
	{
		if ( m_pBot.distanceFrom(ent) > 200 )
			return false;
		if ( ent == m_pBot.m_pPlayer )
			return false;
		if ( ent.pev.flags & FL_CLIENT == FL_CLIENT )
			return true;
		if ( ent.pev.flags & FL_MONSTER == FL_MONSTER )
			return true;

		return false;		
	}

	int getFlags ( bool bBodyVisible, bool bHeadVisible )
	{
		int ret = 0;

		if ( bBodyVisible )
			ret |= VIS_FL_BODY;
		
		if ( bHeadVisible )
			ret |= VIS_FL_HEAD;

		return ret;
	}

	int isVisible ( int iIndex )
	{
		return getFlags(bits_body.getBit(iIndex),bits_head.getBit(iIndex));
	}

	void setVisible ( CBaseEntity@ ent, bool bBodyVisible, bool bHeadVisible )
	{
		if ( ent is null )
		{
			// ARG?
			return;
		}
		
		int flags = getFlags(bBodyVisible,bHeadVisible);
		int iIndex = ent.entindex();
		bool wasVisible = isVisible(iIndex) > 0;

		//BotMessage("setVisible iIndex = " + iIndex + ", bVisible = " + bVisible + "\n");

		// not visible now
		if ( flags == 0 )
		{
			if ( m_pNearestAvoid == ent )
				m_pNearestAvoid = null;

			// was visible before
			if ( wasVisible ) // indicate state change
				m_pBot.lostVisible(ent);
		}
		else 
		{
			if ( !wasVisible )
				m_pBot.newVisible(ent);
		}

		bits_body.setBit(iIndex,bBodyVisible);
		bits_head.setBit(iIndex,bHeadVisible);
	}	

	void reset ()
	{
		bits_body.reset();
		bits_head.reset();
	}

	void update (  )
	{
		CBasePlayer@ player = m_pBot.m_pPlayer;
		int iLoops = 0;
		CBaseEntity@ pStart = m_pCurrentEntity;

		if ( m_pNearestAvoid.GetEntity() !is null )
		{
			if ( CanAvoid(m_pNearestAvoid) )
				m_fNearestAvoidDist = m_pBot.distanceFrom(m_pNearestAvoid);
			else
				m_pNearestAvoid = null;
		}

		iMaxLoops = m_pVisRevs.GetInt();

		do
		{
			CBaseEntity@ groundEntity = g_EntityFuncs.Instance(player.pev.groundentity);
			int flags = 0;
			bool bBodyVisible = false;
			bool bHeadVisible = false;
				
   			@m_pCurrentEntity = g_EntityFuncs.FindEntityByClassname(m_pCurrentEntity, "*"); 
			
			iLoops ++;
			
			if ( m_pCurrentEntity is null )
			{
				continue;
			}

			if ( m_pCurrentEntity is player )
				continue;

			if ( m_pBot.m_pBlocking.GetEntity() !is m_pCurrentEntity )
			{
				if ( groundEntity !is m_pCurrentEntity )
				{				
					if ( !player.FInViewCone(m_pCurrentEntity) )
					{
						setVisible(m_pCurrentEntity,false,false);
						continue;
					}			

					bBodyVisible = UTIL_IsVisible(player.EyePosition(),m_pCurrentEntity,player);

					if ( m_pCurrentEntity.pev.flags & FL_MONSTER == FL_MONSTER )
						bHeadVisible = UTIL_IsVisible(player.EyePosition(),m_pCurrentEntity.EyePosition());
				
					flags = getFlags(bBodyVisible,bHeadVisible);

					if ( flags == 0 )
					{
						setVisible(m_pCurrentEntity,false,false);
						continue;		
					}

					if ( CanAvoid(m_pCurrentEntity) )
					{
						if ( m_pNearestAvoid.GetEntity() is null || (m_pBot.distanceFrom(m_pCurrentEntity) < m_fNearestAvoidDist) )
						{
							m_pNearestAvoid =  m_pCurrentEntity;
						}
					}
				}
			}

			if ( bBodyVisible && m_pCurrentEntity.GetClassname() == "grenade")
			{
				if ( m_pBot.distanceFrom(m_pCurrentEntity) < 300.0f )
				{
					if ( m_pCurrentEntity.pev.owner !is null )
					{
						CBaseEntity@ pentOwner = g_EntityFuncs.Instance(m_pCurrentEntity.pev.owner);

						if ( m_pBot.IsEnemy(pentOwner,false) )
							m_pBot.TakeCover(UTIL_EntityOrigin(m_pCurrentEntity));
					}
				}
			}

			setVisible(m_pCurrentEntity,bBodyVisible,bHeadVisible);

		}while ( iLoops < iMaxLoops );

		if ( isAvoiding() )
		{
			m_pBot.setAvoiding(true);;
			m_pBot.setAvoidVector(getAvoidVector());
		}
		else
			m_pBot.setAvoiding(false);

	}

	bool isAvoiding ()
	{
		return m_pNearestAvoid.GetEntity() !is null;
	}

	Vector getAvoidVector ()
	{
		return UTIL_EntityOrigin(m_pNearestAvoid.GetEntity());
	}

	CBaseEntity@ m_pCurrentEntity = null;
	//array<int> m_VisibleList;
	int iMaxLoops = 200;
	CBits@ bits_body;
	CBits@ bits_head;
	RCBot@ m_pBot;
	
};