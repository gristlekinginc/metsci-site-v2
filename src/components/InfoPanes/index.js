import clsx from 'clsx';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

const InfoPanesList = [
  {
    title: 'MetSci Podcast',
    description: 'Learn LoRaWAN from industry experts.',
    link: 'https://pod.metsci.show',
    iconDark: '/img/icon_images/white-mic-transparent.png',
    iconLight: '/img/icon_images/orange-mic-transparent.png',
    buttonText: 'Listen Now'
  },
  {
    title: 'Console Access',
    description: 'Access the MeteoScientific Console.',
    link: 'https://console.meteoscientific.com',
    iconDark: '/img/icon_images/white-console-transparent.png',
    iconLight: '/img/icon_images/orange-console-transparent.png',
    buttonText: 'Open Console'
  },
  {
    title: 'MetSci Projects',
    description: 'Explore projects built by MeteoScientific.',
    isProjectsPane: true // Special flag for custom layout
  }
];

// Projects data for the MetSci Projects pane
const ProjectsList = [
  {
    title: 'Dashboard',
    link: 'https://grafana.meteoscientific.com/public-dashboards/e6bd9074e3ad4fad935bbcacb510059b',
    icon: '/img/icon_images/project_icons/cirrus-dashboard.png'
  },
  {
    title: 'Sled Push',
    link: 'https://sled.meteoscientific.com',
    icon: '/img/icon_images/project_icons/cirrus-sled-driver.png'
  },
  {
    title: 'Parking',
    link: 'https://parking.paleotreats.com',
    icon: '/img/icon_images/project_icons/cirrus-parking.png'
  }
];

function InfoPane({title, description, link, iconDark, iconLight, buttonText}) {
  return (
    <div className={clsx('col col--4')}>
      <div className={styles.infoPane}>
        <div className={styles.infoPaneIcon}>
          <img 
            src={iconDark} 
            alt={title}
            className={styles.iconDark}
          />
          <img 
            src={iconLight} 
            alt={title}
            className={styles.iconLight}
          />
        </div>
        <h3 className={styles.infoPaneTitle}>{title}</h3>
        <p className={styles.infoPaneDescription}>{description}</p>
        <Link 
          to={link} 
          className={styles.infoPaneButton}
          target="_blank"
          rel="noopener noreferrer"
        >
          {buttonText}
        </Link>
      </div>
    </div>
  );
}

function ProjectsPane({title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className={styles.infoPane}>
        {/* Cirrus Tools logo at the top */}
        <div className={styles.infoPaneIcon}>
          <img 
            src="/img/icon_images/project_icons/cirrus-tools.png"
            alt="Cirrus Tools"
            className={styles.projectsMainIcon}
          />
        </div>
        <h3 className={styles.infoPaneTitle}>{title}</h3>
        <p className={styles.infoPaneDescription}>{description}</p>
        
        {/* Three project icons arranged horizontally */}
        <div className={styles.projectsGrid}>
          {ProjectsList.map((project, idx) => (
            <Link
              key={idx}
              to={project.link}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.projectLink}
              title={project.title}
            >
              <img 
                src={project.icon}
                alt={project.title}
                className={styles.projectIcon}
              />
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}

export default function InfoPanes() {
  return (
    <section className={styles.infoPanes}>
      <div className="container">
        <div className="row">
          {InfoPanesList.map((props, idx) => {
            if (props.isProjectsPane) {
              return <ProjectsPane key={idx} {...props} />;
            }
            return <InfoPane key={idx} {...props} />;
          })}
        </div>
      </div>
    </section>
  );
} 